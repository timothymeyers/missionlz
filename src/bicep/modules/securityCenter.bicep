targetScope = 'subscription'

var bundle = (environment().name == 'AzureUSGovernment' ? [  
  'SqlServers'
  'VirtualMachines'
  'StorageAccounts'
  'ContainerRegistry'
  'KubernetesService'
  'Dns'
  'Arm'
  ] : [
  'KeyVaults'
  'SqlServers'
  'VirtualMachines'
  'StorageAccounts'
  'ContainerRegistry'
  'KubernetesService'
  'SqlServerVirtualMachines'
  'AppServices'
  'Dns'
  'Arm'
])

@description('Turn automatic deployment by ASC of the MMA (OMS VM extension) on or off')
@allowed([
  'On'
  'Off'
])
param autoProvisioning string = 'On'

@description('Turn security policy settings On or Off.')
@allowed([
  'On'
  'Off'
])
param securitySettings string = 'On'

@description('Specify the ID of your custom Log Analytics workspace to collect ASC data.')
param logAnalyticsWorkspaceId string

// security center

resource securityCenterPricing 'Microsoft.Security/pricings@2018-06-01' = [for name in bundle: {
  name: name
  properties: {
    pricingTier: 'Standard'
  }
}]

// auto provisioing

resource autoProvision 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: autoProvisioning
  }
}

resource Microsoft_Security_workspaceSettings_default 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    scope: subscription().id
  }
}

//resource default1 'Microsoft.Security/securityContacts@2017-08-01-preview' = {
//  name: 'securityNotifications'
//  properties: {
//    alertsToAdmins: 'On'
//    alertNotifications: 'On'
//  }
//}

resource Microsoft_Security_policies_default 'Microsoft.Security/policies@2015-06-01-preview' = {
  name: 'default'
  properties: {
    policyLevel: 'Subscription'
    name: 'default'
    unique: 'Off'
    logCollection: 'On'
    recommendations: {
      patch: securitySettings
      baseline: securitySettings
      antimalware: securitySettings
      diskEncryption: securitySettings
      acls: securitySettings
      nsgs: securitySettings
      waf: securitySettings
      sqlAuditing: securitySettings
      sqlTde: securitySettings
      ngfw: securitySettings
      vulnerabilityAssessment: securitySettings
      storageEncryption: securitySettings
      jitNetworkAccess: securitySettings
    }
    pricingConfiguration: {
      selectedPricingTier: 'Standard'
    }
  }
}
