import os
import socket
import dns.resolver
import requests
import pyodbc
import mpmath
import uvicorn
from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Optional, Dict, Any, Iterable, Tuple
import time
import logging

# Azure Identity for Managed Identity authentication
from azure.identity import DefaultAzureCredential

# Load environment variables from .env file if present
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="SAIF API (Secure)", description="Secure AI Foundations API with Entra ID authentication")

# Secure CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["GET", "POST"],  # Restrict methods
    allow_headers=["*"],
)

# Database connection info
SQL_SERVER = os.getenv("SQL_SERVER")
SQL_DATABASE = os.getenv("SQL_DATABASE")
SQL_AUTH_MODE = os.getenv("SQL_AUTH_MODE", "entra").lower()  # Default to Entra ID

def _get_entra_token_bytes() -> bytes:
    """
    Acquire an Entra ID access token for Azure SQL using Managed Identity.
    """
    try:
        credential = DefaultAzureCredential()
        token = credential.get_token("https://database.windows.net/.default").token
        return bytes(token, "UTF-16-LE")  # ODBC expects UTF-16LE
    except Exception as e:
        logger.error(f"Failed to acquire Entra ID token: {str(e)}")
        raise HTTPException(status_code=500, detail="Authentication failed")

def get_db_connection():
    """Create a secure database connection using Entra ID authentication"""
    if not all([SQL_SERVER, SQL_DATABASE]):
        raise HTTPException(status_code=500, detail="Database connection information not configured")

    if SQL_AUTH_MODE == "entra":
        try:
            conn_str = (
                f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                f"SERVER={SQL_SERVER};"
                f"DATABASE={SQL_DATABASE};"
                f"Encrypt=yes;TrustServerCertificate=no"
            )
            # Use Managed Identity authentication
            return pyodbc.connect(conn_str, attrs_before={1256: _get_entra_token_bytes()})
        except Exception as e:
            logger.error(f"Entra ID DB connection failed: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")
    else:
        raise HTTPException(status_code=500, detail="Only Entra ID authentication is supported")

def execute_query(sql: str, params: Optional[Iterable] = None) -> Tuple[Optional[Any], Optional[list]]:
    """
    Execute a parameterized query securely.
    Returns (single_row, all_rows) for convenience.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, [] if params is None else list(params))
        try:
            rows = cur.fetchall()
        except pyodbc.ProgrammingError:
            rows = None  # No results (e.g., INSERT/UPDATE)
        conn.commit()
        return (rows[0] if rows else None, rows)
    except Exception as e:
        logger.error(f"Query execution failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Database query failed")
    finally:
        conn.close()

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "SAIF API (Secure)",
        "version": "2.0.0",
        "description": "Secure diagnostic API with Entra ID authentication",
        "auth_mode": "Entra ID Managed Identity"
    }

@app.get("/api/healthcheck")
async def healthcheck():
    """Health check endpoint with database connectivity test"""
    try:
        # Test database connection
        row, _ = execute_query("SELECT 1 as test")
        db_status = "healthy" if row and row[0] == 1 else "unhealthy"
    except Exception:
        db_status = "unhealthy"
    
    return {
        "status": "healthy",
        "database": db_status,
        "timestamp": time.time()
    }

@app.get("/api/ip")
async def get_ip_info():
    """Returns IP address information"""
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    # Attempt to get public IP with timeout
    try:
        response = requests.get('https://api.ipify.org', timeout=5)
        public_ip = response.text
    except Exception:
        public_ip = "Unable to determine"
        
    return {
        "hostname": hostname,
        "local_ip": local_ip,
        "public_ip": public_ip
    }

@app.get("/api/sqlversion")
async def get_sql_version():
    """Returns the SQL Server version using secure parameterized query"""
    try:
        row, _ = execute_query("SELECT @@VERSION")
        version = row[0] if row else "Unknown"
        return {"sql_version": version}
    except Exception as e:
        logger.error(f"SQL version query failed: {str(e)}")
        return {"error": "Unable to retrieve SQL version"}

@app.get("/api/sqlsrcip")
async def get_sql_source_ip():
    """Returns the source IP as seen by SQL Server"""
    try:
        row, _ = execute_query("SELECT CAST(CONNECTIONPROPERTY('client_net_address') AS VARCHAR(50)) as client_ip")
        client_ip = row[0] if row else "Unknown"
        return {"source_ip": client_ip}
    except Exception as e:
        logger.error(f"Source IP query failed: {str(e)}")
        return {"error": "Unable to retrieve source IP"}

@app.get("/api/dns/{hostname}")
async def resolve_dns(hostname: str):
    """Resolves a DNS name to IP addresses with input validation"""
    # Basic input validation
    if not hostname or len(hostname) > 253:
        raise HTTPException(status_code=400, detail="Invalid hostname")
    
    try:
        a_records = dns.resolver.resolve(hostname, 'A')
        try:
            aaaa_records = dns.resolver.resolve(hostname, 'AAAA')
            aaaa_list = [record.address for record in aaaa_records]
        except dns.resolver.NoAnswer:
            aaaa_list = []
        
        result = {
            "hostname": hostname,
            "a_records": [record.address for record in a_records],
            "aaaa_records": aaaa_list
        }
    except Exception as e:
        result = {
            "hostname": hostname,
            "error": str(e)
        }
    
    return result

@app.get("/api/reversedns/{ip}")
async def reverse_dns(ip: str):
    """Performs reverse DNS lookup with input validation"""
    # Basic IP validation
    try:
        socket.inet_aton(ip)  # Validates IPv4
    except socket.error:
        try:
            socket.inet_pton(socket.AF_INET6, ip)  # Validates IPv6
        except socket.error:
            raise HTTPException(status_code=400, detail="Invalid IP address")
    
    try:
        hostname = socket.gethostbyaddr(ip)[0]
        return {"ip": ip, "hostname": hostname}
    except Exception as e:
        return {"ip": ip, "error": str(e)}

@app.get("/api/curl")
async def curl_url(url: str):
    """Makes an HTTP request to a specified URL with security restrictions"""
    # Security validation
    if not url.startswith(('http://', 'https://')):
        raise HTTPException(status_code=400, detail="Invalid URL protocol")
    
    # Block internal/local addresses
    blocked_hosts = ['localhost', '127.0.0.1', '0.0.0.0', '10.', '192.168.', '172.']
    if any(blocked in url.lower() for blocked in blocked_hosts):
        raise HTTPException(status_code=400, detail="Access to internal addresses is blocked")
    
    try:
        response = requests.get(url, timeout=5, allow_redirects=False)
        return {
            "url": url,
            "status_code": response.status_code,
            "content_type": response.headers.get('Content-Type'),
            "body_preview": response.text[:500]  # First 500 chars only
        }
    except Exception as e:
        return {"url": url, "error": str(e)}

@app.get("/api/pi")
async def calculate_pi(digits: int = 1000):
    """Calculates PI to test CPU load with input validation"""
    try:
        if digits < 1 or digits > 10000:  # Reduced limit for security
            raise HTTPException(status_code=400, detail="Digits must be between 1 and 10,000")
            
        # Set precision and calculate PI
        mpmath.mp.dps = digits + 2
        pi_value = str(mpmath.mp.pi)[:digits+2]  # +2 for "3."
        
        return {
            "digits": digits,
            "pi": pi_value,
            "computation_time": f"{time.time()}"
        }
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        return {"error": str(e)}

# Remove the insecure /api/printenv endpoint entirely
# Environment variables should never be exposed in production

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
