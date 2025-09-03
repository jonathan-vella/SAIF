metadata name = 'Secure App Service with Managed Identity'
metadata description = 'Creates App Service with Managed Identity enabled and secure configuration'
metadata owner = 'SAIF Team'
metadata version = '1.0.0'

@description('Name of the App Service')
param appServiceName string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
param skuName string = 'B1'

@description('App Service Plan SKU tier')
param skuTier string = 'Basic'

@description('Container registry name')
param containerRegistryName string

@description('Container image name and tag')
param containerImageName string = 'saif/api-secure:latest'

@description('SQL Server name')
param sqlServerName string

@description('SQL Database name')
param sqlDatabaseName string

@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Common tags for resources')
param tags object = {}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service with Managed Identity
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerImageName}'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'SQL_SERVER'
          value: '${sqlServerName}${environment().suffixes.sqlServerHostname}'
        }
        {
          name: 'SQL_DATABASE'
          value: sqlDatabaseName
        }
        {
          name: 'SQL_AUTH_MODE'
          value: 'entra'
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
      ]
    }
  }
}

// Configure container registry access for App Service
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appService.id, containerRegistry.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Reference to existing container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output managedIdentityPrincipalId string = appService.identity.principalId
output managedIdentityTenantId string = appService.identity.tenantId
