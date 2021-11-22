param userManagedIdentityName string
param location string = resourceGroup().location
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userManagedIdentityName
  location: location
}

output userResourceId string = userManagedIdentity.id
output userPrincipalId string = userManagedIdentity.properties.principalId
