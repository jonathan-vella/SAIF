// SQL module: Logical SQL Server (educational baseline keeps public access)
metadata name        = 'sql.server'
metadata description = 'Creates a SQL logical server with public network access enabled (SAIF training)'

@description('Server name')
param name string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Administrator login username')
param administratorLogin string

@secure()
@description('Administrator login password')
param administratorLoginPassword string

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
}

output id string = sqlServer.id
output name string = sqlServer.name
output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
