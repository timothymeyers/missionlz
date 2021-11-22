/*
Deploys a web accessible basic Linux container using Azure App Services.   This example requires two items:

--Azure Key Vault:  Must have secret's defined for the registry URL, registry password, and registry username.  See ./src/bicep/examples/keyVault for an example key vault deployment. 
--Azure Container Registry:  Must have the container image deployed and tagged with the label 'prod'.   For example: nginx:prod.

Once you have both items deployed and configured, add the names to your deploymentVariables.json file.  This will permit this template and any other template which needs a container registry or key vault to use the ones already deployed.  

*/
targetScope = 'subscription'
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
param keyVaultName string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultName}'
param keyVaultResourceGroup string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultResourceGroup}'
param keyVaultSubId string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultSubid}'
param appServicePlanName string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanName}'
param appServicePlanResourceGroup string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanResourceGroup}'
param appServicePlanSubId string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanSubId}'
param containerRegistryName string
param containerRegistryResourceGroup string
param containerRegistrySubId string

param appName string = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-${deployment().location}-webapp'

resource keyVaut 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultSubId, keyVaultResourceGroup )
}
module appServiceApp 'modules/containerWebApp.bicep' = {
  name: appName
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    appServiceAppName: appName
    dockerRegistryPassword: keyVaut.getSecret('dockerRegistryPassword')
    dockerRegistryUrl: keyVaut.getSecret('dockerRegistryUrl')
    dockerRegistryUsername: keyVaut.getSecret('dockerRegistryUsername')
  }
}
