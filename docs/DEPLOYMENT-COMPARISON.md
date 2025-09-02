# SAIF Deployment Guide - Secure vs Original

This document outlines the differences between deploying the original SAIF (vulnerable for training) and the secure SAIF with Entra ID authentication.

## Quick Comparison

| Aspect | Original SAIF | Secure SAIF |
|--------|---------------|-------------|
| **Purpose** | Security training & vulnerability demonstration | Production-ready secure implementation |
| **Database Auth** | SQL Server authentication (username/password) | Entra ID Managed Identity |
| **Infrastructure** | `main.bicep` | `main-secure.bicep` |
| **API Container** | `api/` directory | `api-entra/` directory |
| **Setup Complexity** | Simple (docker-compose up) | Moderate (requires Entra ID configuration) |
| **Security Level** | Deliberately vulnerable | Production security standards |

## Deployment Options

### Option 1: Original SAIF (Training/Demo)

**Use when:**
- Conducting security training
- Demonstrating vulnerabilities  
- Educational hackathons
- Penetration testing practice

**Deployment:**
```powershell
# Local development
docker-compose up

# Azure deployment  
.\scripts\Deploy-SAIF-Complete.ps1
```

**Features:**
- ✅ Quick setup (5 minutes)
- ✅ No Azure AD configuration needed
- ✅ Built-in vulnerabilities for learning
- ❌ Not suitable for production
- ❌ Uses hardcoded credentials
- ❌ Vulnerable to SQL injection

### Option 2: Secure SAIF (Production)

**Use when:**
- Production workloads
- Compliance requirements
- Security-first environments
- Enterprise deployments

**Deployment:**
```powershell
# Azure deployment with secure infrastructure
az deployment group create \
  --resource-group "rg-saif-secure" \
  --template-file "infra/main-secure.bicep" \
  --parameters \
    environmentName="prod" \
    entraAdminEmail="admin@company.com" \
    entraAdminObjectId="guid-here"

# Configure database authentication
.\scripts\Configure-EntraIdSqlAuth.ps1 -ResourceGroupName "rg-saif-secure" ...
```

**Features:**
- ✅ Enterprise security standards
- ✅ Entra ID integration
- ✅ No hardcoded credentials
- ✅ Input validation & protection
- ❌ More complex setup (30 minutes)
- ❌ Requires Azure AD admin permissions

## Detailed Deployment Steps

### Original SAIF Deployment

1. **Clone repository**
   ```bash
   git clone https://github.com/jonathan-vella/SAIF.git
   cd SAIF
   ```

2. **Local deployment (Docker)**
   ```bash
   docker-compose up
   # Access: http://localhost:8080
   ```

3. **Azure deployment**
   ```powershell
   .\scripts\Deploy-SAIF-Complete.ps1
   # Follow prompts for resource group and naming
   ```

4. **Testing**
   ```powershell
   .\scripts\Test-SAIFLocal.ps1
   ```

### Secure SAIF Deployment

1. **Prerequisites check**
   ```powershell
   # Verify Azure CLI login
   az account show
   
   # Check permissions (should have Contributor + User Access Administrator)
   az role assignment list --assignee $(az ad signed-in-user show --query objectId -o tsv)
   ```

2. **Deploy infrastructure**
   ```powershell
   # Create resource group
   az group create --name "rg-saif-secure" --location "East US"
   
   # Deploy secure infrastructure
   az deployment group create \
     --resource-group "rg-saif-secure" \
     --template-file "infra/main-secure.bicep" \
     --parameters \
       environmentName="prod" \
       entraAdminEmail="your-admin@company.com" \
       entraAdminObjectId="your-admin-object-id"
   ```

3. **Build and push containers**
   ```powershell
   # Get ACR name from deployment
   $acrName = az deployment group show \
     --resource-group "rg-saif-secure" \
     --name "main-secure" \
     --query "properties.outputs.containerRegistryName.value" -o tsv
   
   # Build secure API
   az acr build --registry $acrName --image saif/api-secure:latest ./api-entra
   
   # Build web app (unchanged)
   az acr build --registry $acrName --image saif/web:latest ./web
   ```

4. **Configure database authentication**
   ```powershell
   .\scripts\Configure-EntraIdSqlAuth.ps1 \
     -ResourceGroupName "rg-saif-secure" \
     -SqlServerName "sql-saif-123456" \
     -DatabaseName "saifdb" \
     -AppServiceName "app-saif-api-123456" \
     -EntraAdminEmail "your-admin@company.com" \
     -EntraAdminObjectId "your-admin-object-id"
   ```

5. **Test deployment**
   ```powershell
   .\scripts\Test-EntraIdConnection.ps1 \
     -ResourceGroupName "rg-saif-secure" \
     -AppServiceName "app-saif-api-123456"
   ```

## Environment Variables Comparison

### Original SAIF
```bash
# Database connection (vulnerable)
SQL_SERVER=your-server.database.windows.net
SQL_DATABASE=saifdb
SQL_USERNAME=saifadmin
SQL_PASSWORD=your-password

# API configuration
API_URL=http://api:8000
API_KEY=insecure_api_key_12345
```

### Secure SAIF
```bash
# Database connection (secure)
SQL_SERVER=your-server.database.windows.net
SQL_DATABASE=saifdb
SQL_AUTH_MODE=entra

# API configuration (no hardcoded keys)
API_URL=https://app-saif-api-123456.azurewebsites.net
```

## Infrastructure Resources Comparison

### Original Infrastructure (`main.bicep`)
- Basic App Service Plan
- App Services with system-assigned identity
- SQL Server with SQL authentication
- Container Registry with admin user enabled
- Minimal security configuration

### Secure Infrastructure (`main-secure.bicep`)
- App Service with enhanced security settings
- SQL Server with Entra ID administrator
- Managed Identity-based authentication
- Container Registry with admin user disabled
- Security-first configuration

## Post-Deployment Configuration

### Original SAIF
```powershell
# Minimal configuration needed
# System is ready to use immediately
# Contains deliberate vulnerabilities for training

# Access vulnerable endpoints:
# /api/printenv - Environment disclosure
# /api/sqlversion?query='; DROP TABLE... - SQL injection
# /api/curl?url=http://localhost/admin - SSRF
```

### Secure SAIF
```powershell
# Additional security configuration recommended:

# 1. Restrict SQL Server firewall (remove 0.0.0.0-255.255.255.255 rule)
az sql server firewall-rule delete \
  --resource-group "rg-saif-secure" \
  --server "sql-saif-123456" \
  --name "AllowDevelopment"

# 2. Enable Application Insights
az monitor app-insights component create \
  --app "saif-insights" \
  --location "East US" \
  --resource-group "rg-saif-secure"

# 3. Configure custom domain and SSL certificate
az webapp config hostname add \
  --webapp-name "app-saif-api-123456" \
  --resource-group "rg-saif-secure" \
  --hostname "api.yourdomain.com"
```

## Cost Comparison

### Original SAIF (Basic deployment)
- App Service Plan (B1): ~$13/month
- SQL Database (Basic): ~$5/month  
- Container Registry (Basic): ~$5/month
- **Total: ~$23/month**

### Secure SAIF (Production deployment)
- App Service Plan (S1 recommended): ~$25/month
- SQL Database (S0 recommended): ~$15/month
- Container Registry (Standard recommended): ~$20/month
- Application Insights: ~$2/month
- **Total: ~$62/month**

## Monitoring & Observability

### Original SAIF
- Basic App Service logs
- Limited monitoring
- Manual troubleshooting

### Secure SAIF  
- Application Insights integration
- Structured logging
- Automated alerts
- Performance monitoring
- Security event tracking

## Maintenance Considerations

### Original SAIF
- ✅ Simple updates (docker-compose pull)
- ✅ Minimal dependencies
- ❌ Security patches critical
- ❌ No compliance reporting

### Secure SAIF
- ✅ Enterprise-grade security
- ✅ Compliance-ready logging  
- ✅ Automated security updates
- ❌ More complex update process
- ❌ Requires security expertise

## Migration Path

If you need to migrate from Original to Secure SAIF:

1. **Deploy secure infrastructure** in parallel (different resource group)
2. **Migrate data** using Azure Database Migration Service
3. **Update web application** configuration to new API endpoint
4. **Test thoroughly** in staging environment
5. **Switch DNS/traffic** to secure environment
6. **Decommission original** resources

## Decision Matrix

Choose **Original SAIF** if:
- ✅ Educational/training purpose
- ✅ Demonstrating vulnerabilities
- ✅ Quick proof-of-concept
- ✅ Development environment
- ✅ Security testing/red team

Choose **Secure SAIF** if:
- ✅ Production workload
- ✅ Compliance requirements
- ✅ Enterprise environment  
- ✅ Customer-facing application
- ✅ Long-term deployment

## Support Resources

### Original SAIF
- [Original deployment guide](../DEPLOY.md)
- [Troubleshooting script](../scripts/Test-SAIFLocal.ps1)
- Community forums and GitHub issues

### Secure SAIF
- [Secure API documentation](../api-entra/README.md)
- [Configuration scripts](../scripts/)
- Enterprise support through Azure
- Security-focused documentation

---

**Recommendation**: Start with Original SAIF for learning and training, then graduate to Secure SAIF for any production use cases.
