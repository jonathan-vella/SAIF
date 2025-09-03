// Security module: Role assignment AcrPull for a principal on a scope
metadata name        = 'security.roleAcrPull'
metadata description = 'Assigns AcrPull role to a principal at a given scope'

@description('Scope for the role assignment (e.g., ACR resource ID)')
param scope string

@description('Principal (service principal) object ID')
param principalId string

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource ra 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scope, principalId, 'AcrPull')
  scope: scope
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output id string = ra.id
