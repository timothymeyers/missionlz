//////////
// CONSTS
//////////

var dnsLabelPrefix = toLower('${virtualMachineName}-${uniqueString(resourceGroup().id)}')
var subnetName = '${virtualMachineName}Subnet'
var subnetAddressPrefix = '10.0.125.0/27'

var networkSecurityGroupName = '${virtualMachineName}NetworkSecurityGroup'

var virtualMachineNetworkInterfaceName = '${virtualMachineName}NetworkInterface'
var virtualMachinePublicIPAddressName = '${virtualMachineName}publicIPAddress'

//////////
// PARAMS
//////////

@description('The location to deploy your Virtual Machine')
param location string = resourceGroup().location

@description('The administrator username for your Virtual Machine')
param adminUsername string = 'azureuser'

@description('The password for logging into the admin account')
param adminPassword string

@description('The version of Ubuntu to use for your Virtual Machine')
param ubuntuOSVersion string = '18.04-LTS'

@description('The name of your Virtual Machine')
param virtualMachineName string = 'integrationTestVM3'

@description('The size of your Virtual Machine')
param virtualMachineSize string = 'Standard_B2s'

@description('The disk to use for your Virtual Machine')
param osDiskType string = 'Standard_LRS'

@description('The shared network interface to attach this VM to')
param sharedSubnetResourceId string

@description('Shared Services network security group id')
param sharedNetworkSecurityGroupResourceId string

@description('Shared services virtual network name')
param sharedVirtualNetworkName string

//////////
// MAIN
//////////

module sharedNetworkInterface '../modules/networkInterface.bicep' = {
  name: 'integrationTestingSharedServices-linuxNetworkInterface'
  params: {
    name: 'linux'
    location: location
    
    ipConfigurationName: 'linuxSharedTestVmIpConfigurationName'
    networkSecurityGroupId: sharedNetworkSecurityGroupResourceId
    privateIPAddressAllocationMethod: 'Dynamic'
    subnetId: sharedSubnetResourceId
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: virtualMachineNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: sharedVirtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: virtualMachinePublicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            primary: false
          }
        }
        {
          id: sharedNetworkInterface.outputs.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: null
    }
  }
}

output hostName string = publicIPAddress.properties.dnsSettings.fqdn
