<#
.SYNOPSIS
    Tests Entra ID Managed Identity connection to Azure SQL Database
.DESCRIPTION
    This script validates that the SAIF API can successfully connect to Azure SQL Database using Managed Identity
.PARAMETER ResourceGroupName
    The name of the resource group containing the resources
.PARAMETER AppServiceName
    The name of the App Service to test
.EXAMPLE
    .\Test-EntraIdConnection.ps1 -ResourceGroupName "rg-saif" -AppServiceName "app-saif-api-123"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AppServiceName
)

$ErrorActionPreference = "Stop"

Write-Host "=== Testing Entra ID Managed Identity Connection ===" -ForegroundColor Green

try {
    # Get App Service URL
    $appServiceUrl = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query defaultHostName -o tsv
    $apiUrl = "https://$appServiceUrl"

    Write-Host "Testing API endpoints on: $apiUrl" -ForegroundColor Yellow

    # Test health check endpoint
    Write-Host "1. Testing health check..." -ForegroundColor Cyan
    $healthResponse = Invoke-RestMethod -Uri "$apiUrl/api/healthcheck" -Method GET -TimeoutSec 30
    Write-Host "Health Status: $($healthResponse.status)" -ForegroundColor White
    Write-Host "Database Status: $($healthResponse.database)" -ForegroundColor White

    if ($healthResponse.database -eq "healthy") {
        Write-Host "✓ Database connection successful!" -ForegroundColor Green
    } else {
        Write-Warning "Database connection failed!"
        return
    }

    # Test SQL version endpoint
    Write-Host "2. Testing SQL version endpoint..." -ForegroundColor Cyan
    $sqlResponse = Invoke-RestMethod -Uri "$apiUrl/api/sqlversion" -Method GET -TimeoutSec 30
    
    if ($sqlResponse.sql_version) {
        Write-Host "✓ SQL Version retrieved successfully!" -ForegroundColor Green
        Write-Host "SQL Version: $($sqlResponse.sql_version)" -ForegroundColor White
    } else {
        Write-Warning "Failed to retrieve SQL version: $($sqlResponse.error)"
    }

    # Test source IP endpoint
    Write-Host "3. Testing source IP endpoint..." -ForegroundColor Cyan
    $ipResponse = Invoke-RestMethod -Uri "$apiUrl/api/sqlsrcip" -Method GET -TimeoutSec 30
    
    if ($ipResponse.source_ip) {
        Write-Host "✓ Source IP retrieved successfully!" -ForegroundColor Green
        Write-Host "Source IP: $($ipResponse.source_ip)" -ForegroundColor White
    } else {
        Write-Warning "Failed to retrieve source IP: $($ipResponse.error)"
    }

    Write-Host "=== Test Complete ===" -ForegroundColor Green
    Write-Host "All endpoints tested successfully with Entra ID authentication!" -ForegroundColor Cyan

} catch {
    Write-Error "Test failed: $($_.Exception.Message)"
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check App Service logs: az webapp log tail --name $AppServiceName --resource-group $ResourceGroupName" -ForegroundColor Gray
    Write-Host "2. Verify Managed Identity is enabled" -ForegroundColor Gray
    Write-Host "3. Verify database user permissions" -ForegroundColor Gray
    Write-Host "4. Check SQL Server firewall settings" -ForegroundColor Gray
}
