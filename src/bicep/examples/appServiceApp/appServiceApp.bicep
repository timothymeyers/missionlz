/*
Deploys a web accessible basic Linux container using Azure App Services.   This example requires two items:

--Azure Key Vault:  Must have secret's defined for the registry URL, registry password, and registry username.  See ./src/bicep/examples/keyVault for an example key vault deployment. 
--Azure Container Registry:  Must have the container image deployed and tagged with the label 'prod'.   For example: nginx:prod.

Once you have both items deployed and configured, add the names to your deploymentVariables.json file.  This will permit this template and any other template which needs a container registry or key vault to use the ones already deployed.  

*/
targetScope = 'subscription'
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
param keyVaultName string
param keyVaultResourceGroup string
param appServiceAppName string

resource keyVaut 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(subscription().subscriptionId, keyVaultResourceGroup )
}
module appServiceApp 'modules/containerWebApp.bicep' = {
  name: appServiceAppName
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    appServiceAppName: appServiceAppName
    dockerRegistryPassword: keyVaut.getSecret('dockerRegistryPassword')
    dockerRegistryUrl: keyVaut.getSecret('dockerRegistryUrl')
    dockerRegistryUsername: keyVaut.getSecret('dockerRegistryUsername')
  }
}
