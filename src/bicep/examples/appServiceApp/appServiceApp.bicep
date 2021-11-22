/*
Deploys a web accessible basic Linux container using Azure App Services.   This example requires two items:

--Azure Key Vault:  Must have secret's defined for the registry URL, registry password, and registry username.  See ./src/bicep/examples/keyVault for an example key vault deployment. 
--Azure Container Registry:  Must have the container image deployed and tagged with the label 'prod'.   For example: nginx:prod.

Once you have both items deployed and configured, add the names to your deploymentVariables.json file.  This will permit this template and any other template which needs a container registry or key vault to use the ones already deployed.  

Note:  Do not forget to update deploymentVariables.json with the name, resource group, and subscription id of your Key Vault and App Service Plan
*/
targetScope = 'subscription'
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@description('The name of the key vault to utilize in support of this deployment.  If unspecified, the template will attempt to use the value from mlzDeploymentVariabes.')
param keyVaultName string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultName}'
@description('The name of the key vault resource group to utilize in support of this deployment.  If unspecified, the template will attempt to use value from mlzDeploymentVariabes.')
param keyVaultResourceGroup string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultResourceGroup}'
@description('The Azure subscription Id where the key vault is deployed.  If unspecified, the template will attempt to use the value from mlzDeploymentVariabes.')
param keyVaultSubId string = '${mlzDeploymentVariables.mlzKeyVault.Value.keyVaultSubid}'
@description('The name of the app service plan to utilize in support of this deployment.  If unspecified, the template will attempt to use the value from mlzDeploymentVariables')
param appServicePlanName string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanName}'
@description('The name of the app service plan resource group to utilize in support of this deployment.  If unspecified, the template will attempt to use value from mlzDeploymentVariabes.')
param appServicePlanResourceGroup string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanResourceGroup}'
@description('The Azure subscription Id where the app service plan is deployed. If unspecified, the template will attempt to use value from mlzDeploymentVariabes.')
param appServicePlanSubId string = '${mlzDeploymentVariables.mlzAppServicePlan.Value.appServicePlanSubId}'
@description('The basic name of the container image which is loaded into your Azure Container Registry.  For example, a base container name would be "nginx"')
param containerBaseImageName string = 'nginx'
@description('The image tag for the container image which will be deployed as part of this deployment.  An example image tag might be "latest".')
param containerImageTag string = 'latest'

var dockerImageName = '${containerBaseImageName}:${containerImageTag}'
var appServiceAppName = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-${containerBaseImageName}'
var managedIdenityRoleGUID = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultSubId, keyVaultResourceGroup)
}
module appServiceApp 'modules/containerWebApp.bicep' = {
  name: containerBaseImageName
  scope: resourceGroup(keyVaultResourceGroup)
  params: {
    appServiceAppName: appServiceAppName
    dockerRegistryPassword: keyVault.getSecret('dockerRegistryPassword')
    dockerRegistryUrl: keyVault.getSecret('dockerRegistryUrl')
    dockerRegistryUsername: keyVault.getSecret('dockerRegistryUsername')
    appServicePlanName: appServicePlanName
    appServicePlanRGName: appServicePlanResourceGroup
    appServicePlanSubId: appServicePlanSubId
    dockerImageName: dockerImageName
    userManagedPrincipalId: deployScriptUserManagedId.outputs.userResourceId
  }
  dependsOn: [
    umiRoleAssignment
  ]
}

module deployScriptUserManagedId 'modules/appUserManagedIdenity.bicep' = {
  scope: resourceGroup(appServicePlanSubId, appServicePlanResourceGroup)
  name: 'deployScriptUserManagedId'
  params: {
    userManagedIdentityName: '${subscription().displayName}-deploy-contributor'
  }
}

resource umiRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('${subscription().displayName}${deployment().name}')
  scope: subscription()
  properties: {
    principalId: deployScriptUserManagedId.outputs.userPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',managedIdenityRoleGUID)
  }
}

output managedIdenityId string = deployScriptUserManagedId.outputs.userResourceId
output azureWebAppName string = appServiceApp.outputs.appServiceAppName
output azureWebAppResourceGroupName string = appServiceApp.outputs.appServiceAppResourceGroup
