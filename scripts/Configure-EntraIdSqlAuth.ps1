<#
.SYNOPSIS
    Configures Azure SQL Database for Entra ID Managed Identity authentication
.DESCRIPTION
    This script sets up the necessary configuration for the SAIF API to connect to Azure SQL Database using Managed Identity
.PARAMETER ResourceGroupName
    The name of the resource group containing the SQL Server
.PARAMETER SqlServerName
    The name of the SQL Server
.PARAMETER DatabaseName
    The name of the database to configure
.PARAMETER AppServiceName
    The name of the App Service that will connect to the database
.PARAMETER EntraAdminEmail
    The email address of the Entra ID admin user
.PARAMETER EntraAdminObjectId
    The object ID of the Entra ID admin user
.EXAMPLE
    .\Configure-EntraIdSqlAuth.ps1 -ResourceGroupName "rg-saif" -SqlServerName "sql-saif-123" -DatabaseName "saifdb" -AppServiceName "app-saif-api-123" -EntraAdminEmail "admin@contoso.com" -EntraAdminObjectId "12345678-1234-1234-1234-123456789012"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$SqlServerName,
    
    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory = $true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory = $true)]
    [string]$EntraAdminEmail,
    
    [Parameter(Mandatory = $true)]
    [string]$EntraAdminObjectId
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== Configuring Azure SQL Database for Entra ID Authentication ===" -ForegroundColor Green

try {
    # 1. Set Entra ID admin for SQL Server
    Write-Host "Setting Entra ID admin for SQL Server: $SqlServerName" -ForegroundColor Yellow
    az sql server ad-admin create `
        --resource-group $ResourceGroupName `
        --server-name $SqlServerName `
        --display-name $EntraAdminEmail `
        --object-id $EntraAdminObjectId

    # 2. Get App Service Managed Identity details
    Write-Host "Getting App Service Managed Identity details..." -ForegroundColor Yellow
    $appIdentity = az webapp identity show --name $AppServiceName --resource-group $ResourceGroupName | ConvertFrom-Json
    
    if (-not $appIdentity.principalId) {
        Write-Host "Enabling Managed Identity for App Service: $AppServiceName" -ForegroundColor Yellow
        $appIdentity = az webapp identity assign --name $AppServiceName --resource-group $ResourceGroupName | ConvertFrom-Json
    }
    
    $managedIdentityObjectId = $appIdentity.principalId
    Write-Host "App Service Managed Identity Object ID: $managedIdentityObjectId" -ForegroundColor Cyan

    # 3. Create SQL script for database user creation
    $sqlScript = @"
-- Create contained database user for Managed Identity
CREATE USER [$AppServiceName] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [$AppServiceName];
ALTER ROLE db_datawriter ADD MEMBER [$AppServiceName];
ALTER ROLE db_ddladmin ADD MEMBER [$AppServiceName];

-- Verify user creation
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = '$AppServiceName';
"@

    # Save SQL script to temp file
    $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $sqlScript | Out-File -FilePath $tempSqlFile -Encoding UTF8

    Write-Host "SQL script created at: $tempSqlFile" -ForegroundColor Cyan
    Write-Host "SQL Script Content:" -ForegroundColor Yellow
    Write-Host $sqlScript -ForegroundColor Gray

    # 4. Get access token for SQL connection
    Write-Host "Getting access token for SQL database connection..." -ForegroundColor Yellow
    $accessToken = az account get-access-token --resource=https://database.windows.net/ --query accessToken -o tsv

    # 5. Execute SQL script using sqlcmd with access token
    Write-Host "Executing SQL script to create database user..." -ForegroundColor Yellow
    $sqlServerFqdn = "$SqlServerName.database.windows.net"
    
    # Note: sqlcmd with access token requires sqlcmd version 17.0 or higher
    sqlcmd -S $sqlServerFqdn -d $DatabaseName -G -P $accessToken -i $tempSqlFile

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database user created successfully!" -ForegroundColor Green
    } else {
        Write-Warning "sqlcmd execution may have failed. Please verify manually."
        Write-Host "Manual verification steps:" -ForegroundColor Yellow
        Write-Host "1. Connect to database using Azure Data Studio or SSMS as Entra ID admin" -ForegroundColor Gray
        Write-Host "2. Execute the following SQL:" -ForegroundColor Gray
        Write-Host $sqlScript -ForegroundColor Gray
    }

    # 6. Clean up temp file
    Remove-Item -Path $tempSqlFile -Force

    # 7. Update App Service configuration
    Write-Host "Updating App Service configuration..." -ForegroundColor Yellow
    az webapp config appsettings set `
        --resource-group $ResourceGroupName `
        --name $AppServiceName `
        --settings SQL_AUTH_MODE=entra

    Write-Host "=== Configuration Complete ===" -ForegroundColor Green
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Entra ID admin set: $EntraAdminEmail" -ForegroundColor White
    Write-Host "- Database user created: $AppServiceName" -ForegroundColor White
    Write-Host "- App Service configured for Entra ID auth" -ForegroundColor White
    Write-Host "- Managed Identity Object ID: $managedIdentityObjectId" -ForegroundColor White

} catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    Write-Host "Please check the following:" -ForegroundColor Yellow
    Write-Host "1. You are logged in to Azure CLI with sufficient permissions" -ForegroundColor Gray
    Write-Host "2. The resource group and resources exist" -ForegroundColor Gray
    Write-Host "3. You have SQL Server admin permissions" -ForegroundColor Gray
    Write-Host "4. sqlcmd is installed and accessible" -ForegroundColor Gray
    exit 1
}
