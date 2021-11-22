param appServiceAppName string
param appServiceAppStagingSlotName string = 'staging'
param appServicePlanName string
param appServicePlanRGName string
param appServicePlanSubId string
param userManagedPrincipalId string
param location string = resourceGroup().location
param dockerImageName string
@secure()
param dockerRegistryUrl string
@secure()
param dockerRegistryUsername string
@secure()
param dockerRegistryPassword string

var dockerImage = 'Docker|${dockerRegistryUrl}/${dockerImageName}'
var webHookName = '${replace('${appServiceAppName}','-','')}'
var shortNameContainerRegistry = split(dockerRegistryUrl, '.')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: appServicePlanName
  scope: resourceGroup(appServicePlanSubId, appServicePlanRGName)
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
      '${userManagedPrincipalId}': {}
    }
  }
  properties: {
    azCliVersion: '2.28.0'
    cleanupPreference: 'Always'
    arguments: '${appServiceAppName} ${resourceGroup().name} ${dockerImageName} ${shortNameContainerRegistry[0]} ${webHookName}'
    scriptContent: '''
      ci_cd_url=$(az webapp deployment container config --name $1 --resource-group $2 --slot staging --enable-cd true --query CI_CD_URL --output tsv);
      result=$(az acr webhook create --name $5 --registry $4 --resource-group $2 --actions push --uri $ci_cd_url --scope $3)
      '''

    retentionInterval: 'PT1H'
  }
}

output appServiceAppName string = appServiceApp.name
output appServiceAppResourceGroup string = appServiceApp.properties.resourceGroup
