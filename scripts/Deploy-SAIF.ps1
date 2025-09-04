<#
.SYNOPSIS
  Chooser for SAIF deployment: v1 (SQL auth) or v2 (Managed Identity)
.DESCRIPTION
  Prompts for version and dispatches to the corresponding script, forwarding common parameters.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [ValidateSet("v1","v2")]
  [string]$version,
  [Parameter(Mandatory=$false)]
  [ValidateSet("germanywestcentral","swedencentral")]
  [string]$location,
  [Parameter(Mandatory=$false)]
  [string]$resourceGroupName,
  [Parameter(Mandatory=$false)]
  [switch]$skipContainers
)

function Show-Banner { param([string]$m); $b = "=" * ($m.Length + 4); Write-Host "`n$b" -ForegroundColor Cyan; Write-Host "| $m |" -ForegroundColor White -BackgroundColor DarkBlue; Write-Host $b -ForegroundColor Cyan; Write-Host "" }

Show-Banner "SAIF Deployment Chooser"

if (-not $version) {
  Write-Host "Select version to deploy:" -ForegroundColor Yellow
  Write-Host "  1) v1 (SQL username/password)" -ForegroundColor White
  Write-Host "  2) v2 (Managed Identity to Azure SQL)" -ForegroundColor White
  $choice = Read-Host "Enter choice (1-2) [2]"
  switch ($choice) {
    '1' { $version = 'v1' }
    default { $version = 'v2' }
  }
}

$commonArgs = @()
if ($PSBoundParameters.ContainsKey('location')) { $commonArgs += @('-location', $location) }
if ($PSBoundParameters.ContainsKey('resourceGroupName')) { $commonArgs += @('-resourceGroupName', $resourceGroupName) }
if ($skipContainers) { $commonArgs += @('-skipContainers') }

if ($version -eq 'v1') {
  & "$PSScriptRoot/Deploy-SAIF-v1.ps1" @commonArgs
} else {
  & "$PSScriptRoot/Deploy-SAIF-v2.ps1" @commonArgs
}
