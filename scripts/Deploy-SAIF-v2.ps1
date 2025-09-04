<#
.SYNOPSIS
    Complete SAIF v2 deployment (managed identity to Azure SQL for API)
.DESCRIPTION
    Deploys SAIF v2 resources in parallel to v1 without modifying v1 artifacts.
.PARAMETER location
    Azure region: germanywestcentral (default) or swedencentral
.PARAMETER resourceGroupName
    Optional RG name; default rg-saifv2-gwc01/swc01
.PARAMETER skipContainers
    Skip container build/push (infra only)
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [ValidateSet("germanywestcentral","swedencentral")]
  [string]$location = "germanywestcentral",
  [Parameter(Mandatory=$false)]
  [string]$resourceGroupName,
  [Parameter(Mandatory=$false)]
  [switch]$skipContainers,
  [Parameter(Mandatory=$false, HelpMessage="Skip configuring SQL firewall and DB permissions")]
  [switch]$skipSqlAccessConfig,
  [Parameter(Mandatory=$false, HelpMessage="Name of the SQL firewall rule for your client IP")]
  [string]$FirewallRuleName = "client-ip",
  [Parameter(Mandatory=$false, HelpMessage="Database roles to grant to the API Managed Identity user")]
  [string[]]$GrantRoles = @('db_datareader'),
  [Parameter(Mandatory=$false, HelpMessage="Optional clientId (GUID) of a User-Assigned Managed Identity to use")]
  [string]$UserAssignedClientId,
  [Parameter(Mandatory=$false, HelpMessage="Optional explicit AAD ObjectId for SQL AAD Admin (bypass auto-resolution)")]
  [ValidatePattern('^[0-9a-fA-F-]{36}$')]
  [string]$aadAdminObjectId
)

function Show-Banner { param([string]$m); $b = "=" * ($m.Length + 4); Write-Host "`n$b" -ForegroundColor Cyan; Write-Host "| $m |" -ForegroundColor White -BackgroundColor DarkBlue; Write-Host $b -ForegroundColor Cyan; Write-Host "" }

Show-Banner "SAIF v2 Deployment"

try { $acct = az account show --query "{name:name, user:user.name, id:id}" -o json | ConvertFrom-Json } catch { Write-Host "Please run 'az login'" -ForegroundColor Red; exit 1 }
Write-Host "Using subscription: $($acct.name) ($($acct.id))" -ForegroundColor Green

if (-not $resourceGroupName) { $resourceGroupName = ($location -eq 'swedencentral') ? 'rg-saifv2-swc01' : 'rg-saifv2-gwc01' }

# Tags
$defaultApp = "SAIF"
$appInput = Read-Host "Application tag [$defaultApp]"
$applicationName = if ([string]::IsNullOrWhiteSpace($appInput)) { $defaultApp } else { $appInput }
$defaultOwner = $acct.user; if ([string]::IsNullOrWhiteSpace($defaultOwner)) { $defaultOwner = "Unknown" }
$ownerInput = Read-Host "Owner tag [$defaultOwner]"
$owner = if ([string]::IsNullOrWhiteSpace($ownerInput)) { $defaultOwner } else { $ownerInput }
$createdBy = "Bicep"
$lastModified = (Get-Date -Format 'yyyy-MM-dd')
$environmentTag = "hackathon"
$purposeTag = "Security Training"

# Resource Group
$rgExists = az group exists --name $resourceGroupName -o tsv
if ($rgExists -eq "false") {
  Write-Host "Creating RG $resourceGroupName in $location" -ForegroundColor Green
  az group create --name $resourceGroupName --location $location --tags `
    Environment=$environmentTag Application="$applicationName" Owner="$owner" CreatedBy="$createdBy" LastModified="$lastModified" Purpose="$purposeTag" | Out-Null
} else {
  Write-Host "RG exists: $resourceGroupName" -ForegroundColor Green
  az group update --name $resourceGroupName --tags `
    Environment=$environmentTag Application="$applicationName" Owner="$owner" CreatedBy="$createdBy" LastModified="$lastModified" Purpose="$purposeTag" | Out-Null
}

# SQL admin password prompt (infra requires params though API won't use it)
$sqlPwd = Read-Host "Enter SQL Admin Password (min 12 chars)" -AsSecureString
$sqlPwdText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPwd))
if ($sqlPwdText.Length -lt 12) { Write-Host "Password too short" -ForegroundColor Red; exit 1 }

# AAD Admin inputs (to automate EXTERNAL PROVIDER support)
$aadAdminLogin = Read-Host "AAD Admin Login (UPN or display name) [default: $($acct.user)]"
if ([string]::IsNullOrWhiteSpace($aadAdminLogin)) { $aadAdminLogin = $acct.user }

if ($PSBoundParameters.ContainsKey('aadAdminObjectId')) {
  Write-Host "Using provided AAD ObjectId override: $aadAdminObjectId" -ForegroundColor Yellow
} else {
  $resolvedObjectId = $null
  # Attempt user lookup
  try { $resolvedObjectId = az ad user show --id $aadAdminLogin --query id -o tsv 2>$null } catch { }
  # Attempt group lookup
  if (-not $resolvedObjectId) { try { $resolvedObjectId = az ad group show --group $aadAdminLogin --query id -o tsv 2>$null } catch { } }
  # Signed-in user fallback
  if (-not $resolvedObjectId) { try { $resolvedObjectId = az ad signed-in-user show --query id -o tsv 2>$null } catch { } }
  # Last resort: Graph direct query (may require additional scopes)
  if (-not $resolvedObjectId) {
    try {
      $graphUserJson = az rest --method GET --url "https://graph.microsoft.com/v1.0/users/$aadAdminLogin" --query id -o tsv 2>$null
      if ($graphUserJson) { $resolvedObjectId = $graphUserJson }
    } catch { }
  }
  if (-not $resolvedObjectId) {
    Write-Host "Could not auto-resolve AAD ObjectId for '$aadAdminLogin'." -ForegroundColor Red
    Write-Host "Provide it explicitly with -aadAdminObjectId <GUID> (find via: az ad signed-in-user show --query id -o tsv)" -ForegroundColor Yellow
    exit 1
  }
  $aadAdminObjectId = $resolvedObjectId
}

Show-Banner "Provisioning Infra (v2)"
$deployName = "main-v2-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$state = az deployment group create `
  --resource-group $resourceGroupName `
  --template-file "../infra-v2/main.bicep" `
  --parameters location=$location sqlAdminPassword=$sqlPwdText applicationName="$applicationName" owner="$owner" `
              aadAdminLogin="$aadAdminLogin" aadAdminObjectId="$aadAdminObjectId" `
  --name $deployName `
  --query "properties.provisioningState" -o tsv
if ($state -ne "Succeeded") { Write-Host "Infra deployment failed" -ForegroundColor Red; exit 1 }

$outs = az deployment group show --resource-group $resourceGroupName --name $deployName --query properties.outputs -o json | ConvertFrom-Json
$acrName = $outs.acrName.value
$apiApp = $outs.apiAppServiceName.value
$webApp = $outs.webAppServiceName.value
$sqlServer = $outs.sqlServerName.value
$sqlDb = $outs.sqlDatabaseName.value
$apiUrl = $outs.apiUrl.value

if (-not $skipContainers) {
  Show-Banner "Build & Push v2 API Container"
  az acr build --registry $acrName --image saifv2/api:latest ../api-v2
  if ($LASTEXITCODE -ne 0) { Write-Host "API v2 image build failed" -ForegroundColor Red; exit 1 }
  Show-Banner "Build & Push Web Container (v1 image reused in v2 registry)"
  az acr build --registry $acrName --image saif/web:latest ../web
  if ($LASTEXITCODE -ne 0) { Write-Host "Web image build failed" -ForegroundColor Red; exit 1 }
  Write-Host "Restarting apps" -ForegroundColor Green
  az webapp restart --name $apiApp --resource-group $resourceGroupName | Out-Null
  az webapp restart --name $webApp --resource-group $resourceGroupName | Out-Null
}

if (-not $skipSqlAccessConfig) {
  Show-Banner "Configuring SQL Firewall & DB Access (Managed Identity)"
  $configureScript = Join-Path $PSScriptRoot 'Configure-SAIF-SqlAccess.ps1'
  if (-not (Test-Path $configureScript)) {
    Write-Host "Configuration script not found: $configureScript" -ForegroundColor Red
  } else {
    try {
      $cfgParams = @{
        location          = $location
        ResourceGroupName = $resourceGroupName
        FirewallRuleName  = $FirewallRuleName
        Roles             = $GrantRoles
      }
      # Only pass UserAssignedClientId if a non-empty, valid GUID is provided
      if (-not [string]::IsNullOrWhiteSpace($UserAssignedClientId)) {
        if ($UserAssignedClientId -match '^[0-9a-fA-F-]{36}$') {
          $cfgParams['UserAssignedClientId'] = $UserAssignedClientId
        } else {
          Write-Host "Ignoring invalid UserAssignedClientId (not a GUID): $UserAssignedClientId" -ForegroundColor Yellow
        }
      }
      & $configureScript @cfgParams
    } catch {
      Write-Host "SQL access configuration failed: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
} else {
  Write-Host "Skipping SQL access configuration (firewall and DB user/roles)" -ForegroundColor Yellow
}

Show-Banner "SAIF v2 Deployment Complete"
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Green
Write-Host "API URL: $($outs.apiUrl.value)" -ForegroundColor Green
Write-Host "Web URL: $($outs.webUrl.value)" -ForegroundColor Green

# Clear sensitive
$sqlPwdText = $null; $sqlPwd = $null
