param appServiceAppName string
param appServiceAppStagingSlotName string = 'staging'
param appServicePlanName string = 'jaiAppServicePlan'
param appServicePlanRGName string = resourceGroup().name
param location string = resourceGroup().location
param dockerImageName string = 'nginx:latest'
@secure()
param dockerRegistryUrl string
@secure()
param dockerRegistryUsername string
@secure()
param dockerRegistryPassword string

var dockerImage = 'Docker|${dockerRegistryUrl}/${dockerImageName}'
var shortNameContainerRegistry = split(dockerRegistryUrl, '.')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: appServicePlanName
  scope: resourceGroup(appServicePlanRGName)
}

resource appServiceApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistryUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: dockerRegistryPassword
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: dockerImage
      alwaysOn: true
    }
  }
  resource appServiceAppStagingSlot 'slots' = {
    name: appServiceAppStagingSlotName
    location: location
    properties: {
      serverFarmId: appServicePlan.id
      siteConfig: {
        appSettings: [
          {
            name: 'DOCKER_REGISTRY_SERVER_URL'
            value: dockerRegistryUrl
          }
          {
            name: 'DOCKER_REGISTRY_SERVER_USERNAME'
            value: dockerRegistryUsername
          }
          {
            name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
            value: dockerRegistryPassword
          }
          {
            name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
            value: 'false'
          }
        ]
        linuxFxVersion: dockerImage
        alwaysOn: true
      }
    }
  }
}
resource deployCI_CD_HookScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployCI_CD_HookScript'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/97ee5f79-e968-4e81-9d67-921c0c107342/resourcegroups/jaitemp/providers/Microsoft.ManagedIdentity/userAssignedIdentities/jaiWebApp': {}
    }
  }
  properties: {
    azCliVersion: '2.28.0'
    cleanupPreference: 'Always'
    arguments: '${appServiceAppName} ${resourceGroup().name} ${dockerImageName} ${shortNameContainerRegistry[0]}'
    scriptContent: '''
      ci_cd_url=$(az webapp deployment container config --name $1 --resource-group $2 --slot staging --enable-cd true --query CI_CD_URL --output tsv);
      result=$(az acr webhook create --name $1 --registry $4 --resource-group $2 --actions push --uri $ci_cd_url --scope $3)
      '''

    retentionInterval: 'PT1H'
  }
}
