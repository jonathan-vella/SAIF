// Main Bicep template for SAIF deployment
metadata name = 'SAIF Infrastructure'
metadata description = 'Deploys the infrastructure for SAIF (Secure AI Foundations) hackathon'
metadata owner = 'SAIF Team'
metadata version = '1.0.0'
metadata lastUpdated = '2025-06-19'
metadata documentation = 'https://github.com/your-org/saif/blob/main/docs/deployment.md'

// Parameters
@description('The Azure region where resources will be deployed')
@allowed([
  'swedencentral'
  'germanywestcentral'
])
param location string = 'germanywestcentral'

@description('The administrator login username for the SQL Server')
param sqlAdminLogin string = 'saifadmin'

@description('The administrator login password for the SQL Server')
@secure()
@minLength(12)
param sqlAdminPassword string

@description('Tags for the resources')
param tags object = {}

@description('Application name to tag resources with')
param applicationName string = 'SAIF'

@description('Owner tag value; typically the deploying user or team')
param owner string = ''

@description('CreatedBy tag value')
param createdBy string = 'Bicep'

@description('Last modified date tag (yyyy-MM-dd). Uses deployment-time default.')
param lastModified string = utcNow('yyyy-MM-dd')

// Variables
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 6)
var acrName = 'acrsaif${uniqueSuffix}'
var appServicePlanName = 'plan-saif-${uniqueSuffix}'
var apiAppServiceName = 'app-saif-api-${uniqueSuffix}'
var webAppServiceName = 'app-saif-web-${uniqueSuffix}'
var sqlServerName = 'sql-saif-${uniqueSuffix}'
var sqlDatabaseName = 'saifdb'
var logAnalyticsName = 'log-saif-${uniqueSuffix}'
var appInsightsName = 'ai-saif-${uniqueSuffix}'

// Default tags applied to all resources
var defaultTags = union(tags, {
  Environment: 'hackathon'
  Application: applicationName
  Owner: owner != '' ? owner : 'Unknown'
  CreatedBy: createdBy
  LastModified: lastModified
  Purpose: 'Security Training'
})

// Observability
module observability './modules/observability/logging.bicep' = {
  name: 'observability-${uniqueSuffix}'
  params: {
    location: location
    tags: defaultTags
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    workspaceSku: 'PerGB2018'
    retentionInDays: 30
  }
}

// Container Registry
module acr './modules/container/registry.bicep' = {
  name: 'acr-${uniqueSuffix}'
  params: {
    name: acrName
    location: location
    tags: defaultTags
    skuName: 'Standard'
    adminUserEnabled: false
  }
}

// Existing reference to ACR for role assignment scope typing
resource acrRes 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// SQL Server (keeps public access for SAIF training)
module sqlServer './modules/sql/server.bicep' = {
  name: 'sql-${uniqueSuffix}'
  params: {
    name: sqlServerName
    location: location
    tags: defaultTags
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
  }
}

// SQL Database
module sqlDatabase './modules/sql/database.bicep' = {
  name: 'sqldb-${uniqueSuffix}'
  dependsOn: [
    sqlServer
  ]
  params: {
    location: location
    tags: defaultTags
    serverName: sqlServerName
    name: sqlDatabaseName
    skuName: 'S1'
    skuTier: 'Standard'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// Firewall rule 0.0.0.0 (Allow Azure Services)
module sqlFirewall './modules/sql/firewallAllowAzure.bicep' = {
  name: 'sqlfw-${uniqueSuffix}'
  dependsOn: [
    sqlServer
  ]
  params: {
    serverName: sqlServerName
  }
}

// App Service Plan (Linux)
module appServicePlan './modules/web/plan.bicep' = {
  name: 'plan-${uniqueSuffix}'
  params: {
    name: appServicePlanName
    location: location
    tags: defaultTags
    skuName: 'P1v3'
    skuTier: 'PremiumV3'
  }
}

// API App Service (container)
module apiAppService './modules/web/site.bicep' = {
  name: 'api-${uniqueSuffix}'
  params: {
    name: apiAppServiceName
    location: location
    tags: defaultTags
    serverFarmId: appServicePlan.outputs.id
    image: '${acr.outputs.loginServer}/saif/api:latest'
    websitesPort: '8000'
    healthCheckPath: '/api/healthcheck'
    appSettings: [
      { name: 'SQL_SERVER', value: sqlServer.outputs.fullyQualifiedDomainName }
      { name: 'SQL_DATABASE', value: sqlDatabaseName }
      { name: 'SQL_USERNAME', value: sqlAdminLogin }
      { name: 'SQL_PASSWORD', value: sqlAdminPassword }
      { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: observability.outputs.appInsightsConnectionString }
    ]
  }
}

// Web App Service (container)
module webAppService './modules/web/site.bicep' = {
  name: 'web-${uniqueSuffix}'
  params: {
    name: webAppServiceName
    location: location
    tags: defaultTags
    serverFarmId: appServicePlan.outputs.id
    image: '${acr.outputs.loginServer}/saif/web:latest'
    websitesPort: '80'
    healthCheckPath: '/'
    appSettings: [
      { name: 'API_URL', value: 'https://${apiAppService.outputs.defaultHostName}' }
      { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: observability.outputs.appInsightsConnectionString }
    ]
  }
}

// Diagnostics: send logs/metrics to Log Analytics
resource apiSite 'Microsoft.Web/sites@2023-01-01' existing = {
  name: apiAppServiceName
}

resource webSite 'Microsoft.Web/sites@2023-01-01' existing = {
  name: webAppServiceName
}

resource sqlSrv 'Microsoft.Sql/servers@2023-05-01-preview' existing = {
  name: sqlServerName
}

resource apiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'ds-api-${uniqueSuffix}'
  scope: apiSite
  dependsOn: [
  apiAppService
  ]
  properties: {
    workspaceId: observability.outputs.logAnalyticsId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource webDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'ds-web-${uniqueSuffix}'
  scope: webSite
  dependsOn: [
  webAppService
  ]
  properties: {
    workspaceId: observability.outputs.logAnalyticsId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource sqlDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'ds-sql-${uniqueSuffix}'
  scope: sqlSrv
  dependsOn: [
  sqlServer
  ]
  properties: {
  workspaceId: observability.outputs.logAnalyticsId
  // NOTE: Log categories vary by SQL resource and SKU. Keeping metrics-only to avoid unsupported categories.
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Grant AcrPull permissions to App Services
resource apiAcrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceId('Microsoft.ContainerRegistry/registries', acrName), apiAppServiceName, 'AcrPull')
  scope: acrRes
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: apiAppService.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource webAcrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceId('Microsoft.ContainerRegistry/registries', acrName), webAppServiceName, 'AcrPull')
  scope: acrRes
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: webAppService.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output acrName string = acr.outputs.name
output acrLoginServer string = acr.outputs.loginServer
output apiAppServiceName string = apiAppService.outputs.name
output webAppServiceName string = webAppService.outputs.name
output apiUrl string = 'https://${apiAppService.outputs.defaultHostName}'
output webUrl string = 'https://${webAppService.outputs.defaultHostName}'
output sqlServerName string = sqlServer.outputs.name
output sqlServerFqdn string = sqlServer.outputs.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabaseName
output logAnalyticsWorkspaceId string = observability.outputs.logAnalyticsId
// Sensitive; avoid outputting in production
// output appInsightsConnectionString string = observability.outputs.appInsightsConnectionString
