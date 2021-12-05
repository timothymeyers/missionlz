targetScope = 'subscription'

param linuxNetworkInterfaceName string = 'linuxVmNetworkInterface'
param linuxNetworkInterfaceIpConfigurationName string = 'linuxVmIpConfiguration'
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'
param linuxVmName string = 'linuxVirtualMachine'
param linuxVmSize string = 'Standard_B2s'
param linuxVmOsDiskCreateOption string = 'FromImage'
param linuxVmOsDiskType string = 'Standard_LRS'
param linuxVmImagePublisher string = 'Canonical'
param linuxVmImageOffer string = 'UbuntuServer'
param linuxVmImageSku string = '18.04-LTS'
param linuxVmImageVersion string = 'latest'
param linuxVmAdminUsername string = 'azureuser'
@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string = 'password'
@secure()
@minLength(14)
param linuxVmAdminPasswordOrKey string = deployRemoteAccess ? '' : newGuid()

param logAnalyticsWorkspaceId string

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: hubVirtualNetworkName
}

resource sharedVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: hubVirtualNetworkName
}

module linuxHubNetworkInterface './networkInterface.bicep' = {
  name: 'remoteAccess-linuxNetworkInterface'
  params: {
    name: linuxNetworkInterfaceName
    location: location
    tags: tags
    
    ipConfigurationName: linuxNetworkInterfaceIpConfigurationName
    networkSecurityGroupId: hubNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: hubSubnetResourceId
  }
}

module linuxHubVirtualMachine './linuxVirtualMachine.bicep' = {
  name: 'remoteAccess-linuxVirtualMachine'
  params: {
    name: linuxVmName
    location: location
    tags: tags

    vmSize: linuxVmSize
    osDiskCreateOption: linuxVmOsDiskCreateOption
    osDiskType: linuxVmOsDiskType
    vmImagePublisher: linuxVmImagePublisher
    vmImageOffer: linuxVmImageOffer
    vmImageSku: linuxVmImageSku
    vmImageVersion: linuxVmImageVersion
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    networkInterfaceName: linuxHubNetworkInterface.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module linuxSharedNetworkInterface './networkInterface.bicep' = {
  name: 'remoteAccess-linuxNetworkInterface'
  params: {
    name: linuxNetworkInterfaceName
    location: location
    tags: tags
    
    ipConfigurationName: linuxNetworkInterfaceIpConfigurationName
    networkSecurityGroupId: sharedNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod
    subnetId: sharedSubnetResourceId
  }
}

module linuxSharedVirtualMachine './linuxVirtualMachine.bicep' = {
  name: 'remoteAccess-linuxVirtualMachine'
  params: {
    name: linuxVmName
    location: location
    tags: tags

    vmSize: linuxVmSize
    osDiskCreateOption: linuxVmOsDiskCreateOption
    osDiskType: linuxVmOsDiskType
    vmImagePublisher: linuxVmImagePublisher
    vmImageOffer: linuxVmImageOffer
    vmImageSku: linuxVmImageSku
    vmImageVersion: linuxVmImageVersion
    adminUsername: linuxVmAdminUsername
    authenticationType: linuxVmAuthenticationType
    adminPasswordOrKey: linuxVmAdminPasswordOrKey
    networkInterfaceName: linuxNetworkInterface.outputs.name
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}
