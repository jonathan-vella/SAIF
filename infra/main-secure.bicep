metadata name = 'SAIF Secure Infrastructure'
metadata description = 'Secure deployment of SAIF with Entra ID authentication'
metadata owner = 'SAIF Team'
metadata version = '2.0.0'

@description('Environment name (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Unique suffix for resource names')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 6)

@description('Entra ID admin email for SQL Server')
param entraAdminEmail string

@description('Entra ID admin object ID for SQL Server')
param entraAdminObjectId string

@description('Enable Entra ID only authentication for SQL Server')
param entraIdOnlyAuth bool = false

@description('SQL Server admin password (only used if Entra ID only auth is disabled)')
@secure()
param sqlAdminPassword string = ''

@description('Current deployment date')
param deploymentDate string = utcNow('yyyy-MM-dd')

// Common tags
var commonTags = {
  Environment: environmentName
  Project: 'SAIF'
  Version: '2.0.0'
  CreatedBy: 'Bicep'
  CreatedDate: deploymentDate
}

// Resource names
var acrName = 'acrsaif${uniqueSuffix}'
var sqlServerName = 'sql-saif-${uniqueSuffix}'
var sqlDatabaseName = 'saifdb'
var appServicePlanName = 'asp-saif-${uniqueSuffix}'
var apiAppServiceName = 'app-saif-api-${uniqueSuffix}'
var webAppServiceName = 'app-saif-web-${uniqueSuffix}'

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: commonTags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // Use Managed Identity instead
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

// Secure SQL Server with Entra ID
module sqlServer 'modules/secureSqlServer.bicep' = {
  name: 'sqlServer-deployment'
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    location: location
    entraAdminLogin: entraAdminEmail
    entraAdminObjectId: entraAdminObjectId
    entraIdOnlyAuth: entraIdOnlyAuth
    sqlAdminPassword: sqlAdminPassword
    tags: commonTags
  }
}

// Secure API App Service with Managed Identity
module apiAppService 'modules/secureAppService.bicep' = {
  name: 'apiAppService-deployment'
  params: {
    appServiceName: apiAppServiceName
    appServicePlanName: appServicePlanName
    location: location
    containerRegistryName: acrName
    containerImageName: 'saif/api-secure:latest'
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    environmentName: environmentName
    tags: commonTags
  }
  dependsOn: [
    containerRegistry
    sqlServer
  ]
}

// Web App Service (keeping original for comparison)
resource webAppServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appServicePlanName}-web'
  location: location
  tags: commonTags
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webAppService 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppServiceName
  location: location
  tags: commonTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: webAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/saif/web:latest'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrName}.azurecr.io'
        }
        {
          name: 'API_URL'
          value: 'https://${apiAppServiceName}.azurewebsites.net'
        }
        {
          name: 'API_KEY'
          value: 'secure_api_key_v2'
        }
      ]
    }
  }
}

// ACR access for web app
resource webAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(webAppService.id, containerRegistry.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: webAppService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output containerRegistryName string = containerRegistry.name
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output sqlServerName string = sqlServer.outputs.sqlServerName
output sqlServerFqdn string = sqlServer.outputs.sqlServerFqdn
output sqlDatabaseName string = sqlServer.outputs.sqlDatabaseName
output apiAppServiceName string = apiAppService.outputs.appServiceName
output apiAppServiceUrl string = apiAppService.outputs.appServiceUrl
output webAppServiceName string = webAppService.name
output webAppServiceUrl string = 'https://${webAppService.properties.defaultHostName}'
output managedIdentityPrincipalId string = apiAppService.outputs.managedIdentityPrincipalId
