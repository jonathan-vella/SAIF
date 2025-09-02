metadata name = 'Secure SQL Server with Entra ID'
metadata description = 'Creates Azure SQL Server with Entra ID authentication enabled'
metadata owner = 'SAIF Team'
metadata version = '1.0.0'

@description('Name of the SQL Server')
param sqlServerName string

@description('Name of the SQL Database')
param sqlDatabaseName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SQL Database SKU')
param sqlDatabaseSku object = {
  name: 'Basic'
  tier: 'Basic'
  capacity: 5
}

@description('Entra ID admin login name')
param entraAdminLogin string

@description('Entra ID admin object ID')
param entraAdminObjectId string

@description('Tenant ID for Entra ID')
param tenantId string = subscription().tenantId

@description('Enable Entra ID only authentication')
param entraIdOnlyAuth bool = false

@description('SQL Server admin password (only used if Entra ID only auth is disabled)')
@secure()
param sqlAdminPassword string = ''

@description('Common tags for resources')
param tags object = {}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: entraIdOnlyAuth ? null : 'sqladmin'
    administratorLoginPassword: entraIdOnlyAuth ? null : sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled' // Can be restricted later
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: sqlDatabaseSku
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
  }
}

// Entra ID Administrator
resource sqlServerEntraAdmin 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: entraAdminLogin
    sid: entraAdminObjectId
    tenantId: tenantId
  }
}

// Firewall rule to allow Azure services
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Optional: Firewall rule for development (remove in production)
resource allowDevelopment 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowDevelopment'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output connectionString string = 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDatabase.name};Authentication=Active Directory Managed Identity;'
