# SAIF API - Secure Entra ID Version

This directory contains a secure version of the SAIF API that uses **Entra ID Managed Identity** for authentication to Azure SQL Database, replacing the vulnerable SQL authentication used in the original version.

## Key Security Improvements

### Authentication & Authorization
- **Entra ID Managed Identity**: Eliminates hardcoded credentials
- **Token-based authentication**: Uses Azure AD access tokens
- **Least privilege access**: Database roles scoped to minimum required permissions

### Database Security  
- **Parameterized queries**: Prevents SQL injection attacks
- **ODBC Driver 18**: Enhanced security and encryption
- **TLS 1.2 encryption**: Secure data transmission

### Application Security
- **Input validation**: URL and parameter validation
- **SSRF protection**: Blocks internal/localhost requests  
- **Rate limiting**: Reduced computation limits
- **Removed vulnerable endpoints**: `/api/printenv` endpoint removed
- **Secure logging**: Structured logging without sensitive data exposure

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Web App       │    │   API App        │    │  Azure SQL DB   │
│                 │────│ (Managed         │────│                 │
│                 │    │  Identity)       │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                Azure Container Registry                         │
│                                                                │
│  ┌─────────────────┐          ┌─────────────────┐             │
│  │  saif/web:latest│          │saif/api-secure  │             │
│  │  (original)     │          │    :latest      │             │
│  └─────────────────┘          └─────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

## Files Overview

### Application Code
- **`app.py`** - Secure API implementation with Entra ID auth
- **`requirements.txt`** - Dependencies including `azure-identity`
- **`Dockerfile`** - Container definition with ODBC Driver 18

### Infrastructure  
- **`../infra/main-secure.bicep`** - Complete secure infrastructure template
- **`../infra/modules/secureAppService.bicep`** - App Service with Managed Identity
- **`../infra/modules/secureSqlServer.bicep`** - SQL Server with Entra ID admin

### Automation Scripts
- **`../scripts/Configure-EntraIdSqlAuth.ps1`** - Database user setup automation
- **`../scripts/Test-EntraIdConnection.ps1`** - Connection validation

## Deployment Guide

### Prerequisites
- Azure CLI installed and logged in
- Docker installed (for local testing)
- Appropriate Azure permissions:
  - Contributor role on resource group
  - User Access Administrator (for role assignments)
  - SQL Server admin permissions

### 1. Deploy Infrastructure

```powershell
# Deploy the secure infrastructure
az deployment group create \
  --resource-group "rg-saif-secure" \
  --template-file "../infra/main-secure.bicep" \
  --parameters \
    environmentName="dev" \
    entraAdminEmail="admin@contoso.com" \
    entraAdminObjectId="12345678-1234-1234-1234-123456789012"
```

### 2. Build and Push Container

```powershell
# Get ACR name from deployment output
$acrName = az deployment group show --resource-group "rg-saif-secure" --name "main-secure" --query "properties.outputs.containerRegistryName.value" -o tsv

# Build and push the secure API container
az acr build --registry $acrName --image saif/api-secure:latest .
```

### 3. Configure Database Authentication

```powershell
# Run the configuration script
..\scripts\Configure-EntraIdSqlAuth.ps1 \
  -ResourceGroupName "rg-saif-secure" \
  -SqlServerName "sql-saif-123456" \
  -DatabaseName "saifdb" \
  -AppServiceName "app-saif-api-123456" \
  -EntraAdminEmail "admin@contoso.com" \
  -EntraAdminObjectId "12345678-1234-1234-1234-123456789012"
```

### 4. Test the Deployment

```powershell
# Validate the secure connection
..\scripts\Test-EntraIdConnection.ps1 \
  -ResourceGroupName "rg-saif-secure" \
  -AppServiceName "app-saif-api-123456"
```

## Local Development

### Using Docker Compose (with Azure SQL)

1. Set environment variables:
```bash
export SQL_SERVER="your-server.database.windows.net"
export SQL_DATABASE="saifdb"
export SQL_AUTH_MODE="entra"
```

2. Ensure you're logged in to Azure CLI:
```bash
az login
```

3. Run the container:
```bash
docker build -t saif-api-secure .
docker run -p 8000:8000 \
  -e SQL_SERVER \
  -e SQL_DATABASE \
  -e SQL_AUTH_MODE \
  -v ~/.azure:/root/.azure:ro \
  saif-api-secure
```

### Testing Locally

The secure API removes several vulnerable endpoints and adds validation:

```bash
# Health check (includes database test)
curl http://localhost:8000/api/healthcheck

# SQL version (secure, parameterized)
curl http://localhost:8000/api/sqlversion

# URL fetching (with SSRF protection)
curl "http://localhost:8000/api/curl?url=https://httpbin.org/json"

# DNS resolution (with validation)
curl http://localhost:8000/api/dns/example.com

# PI calculation (with reduced limits)
curl "http://localhost:8000/api/pi?digits=1000"
```

## Security Comparison

| Feature | Original API | Secure API |
|---------|-------------|------------|
| **Database Auth** | SQL username/password | Entra ID Managed Identity |
| **SQL Queries** | String concatenation (vulnerable) | Parameterized queries |
| **ODBC Driver** | Driver 17, TrustServerCertificate=yes | Driver 18, Encrypt=yes |
| **Input Validation** | None | URL, IP, length validation |
| **SSRF Protection** | None | Blocks internal addresses |
| **Environment Exposure** | `/api/printenv` endpoint | Endpoint removed |
| **API Key** | Hardcoded, exposed | Not used (MI authentication) |
| **Error Handling** | Detailed error exposure | Sanitized error messages |
| **Rate Limiting** | 100K digits PI | 10K digits PI |

## Troubleshooting

### Common Issues

1. **"Authentication failed" error**
   - Verify Managed Identity is enabled on App Service
   - Check Entra ID admin is configured on SQL Server
   - Ensure database user exists with proper permissions

2. **"Database connection failed"**
   - Verify SQL Server firewall allows Azure services
   - Check SQL Server and database names in app settings
   - Validate ODBC Driver 18 is installed

3. **Container fails to start**
   - Check ACR authentication (Managed Identity for pull)
   - Verify container image exists in registry
   - Review App Service logs: `az webapp log tail`

### Validation Commands

```powershell
# Check Managed Identity
az webapp identity show --name "app-saif-api-123456" --resource-group "rg-saif-secure"

# Check App Service settings
az webapp config appsettings list --name "app-saif-api-123456" --resource-group "rg-saif-secure"

# View logs
az webapp log tail --name "app-saif-api-123456" --resource-group "rg-saif-secure"

# Test database connection manually
sqlcmd -S "sql-saif-123456.database.windows.net" -d "saifdb" -G
```

## Migration from Original API

To migrate from the vulnerable version to the secure version:

1. **Deploy secure infrastructure** alongside existing (different resource group recommended)
2. **Configure Entra ID authentication** using provided scripts
3. **Update web application** to point to new secure API endpoint
4. **Test functionality** thoroughly in non-production environment
5. **Gradually migrate traffic** using Azure Traffic Manager or DNS updates
6. **Decommission old resources** once migration is validated

## Next Steps

- **Network Security**: Implement Private Endpoints for SQL Database
- **Key Vault Integration**: Store additional secrets in Azure Key Vault
- **Application Insights**: Enhanced monitoring and alerting
- **DevOps Pipeline**: Automated CI/CD with security scanning
- **Compliance**: Implement additional compliance requirements (GDPR, HIPAA, etc.)

## Contributing

When making changes to the secure API:

1. **Maintain security principles**: Never introduce vulnerabilities
2. **Test thoroughly**: Validate both functionality and security
3. **Document changes**: Update this README and deployment guides
4. **Security review**: Have changes reviewed by security team

## Support

For questions or issues with the secure implementation:

1. Review troubleshooting section above
2. Check Azure service health and status
3. Consult Azure documentation for Managed Identity
4. Contact the SAIF development team
