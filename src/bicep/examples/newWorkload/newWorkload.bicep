targetScope = 'subscription'

@description('The name of the workload being deployed. It is used to calculate the names of resources, including the vnet, subnet, NSG, log storage account, and tags.')
@minLength(3)
@maxLength(24)
param workloadName string

@description('The name of the Azure deployment that was used to deploy the Mission Landing Zone core infrastructure. You can find the deployment name using the Azure Portal under the MLZ hub subscription at Subscriptions --> Deployments, or you can run this AZ CLI command on the MLZ hub subscription to see all deployments in the subscription: az deployment sub list --query [].name')
param mlzHubDeploymentName string

@description('The ID of the subscription containing the Mission Landing Zone firewall, i.e., the hub.')
param hubSubscriptionId string

param resourceGroupName string = '${workloadName}-rg'
param location string = deployment().location
param virtualNetworkName string = '${workloadName}-vnet'
param virtualNetworkAddressPrefix string = '10.0.125.0/26'
param virtualNetworkDiagnosticsLogs array = []
param virtualNetworkDiagnosticsMetrics array = []
param subnetName string = '${workloadName}-subnet'
param subnetAddressPrefix string = '10.0.125.0/27'
param subnetServiceEndpoints array = []
param networkSecurityGroupName string = '${workloadName}-nsg'
param networkSecurityGroupRules array = []
param networkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
param networkSecurityGroupDiagnosticsMetrics array = []
param logStorageAccountName string = toLower(take('logs${uniqueString(subscription().subscriptionId, workloadName)}', 24))
param logStorageSkuName string = 'Standard_GRS'
param resourceIdentifier string = '${workloadName}${uniqueString(workloadName)}'
param tags object = {
  'resourceIdentifier': resourceIdentifier
}

// Load the MLZ hub network deployment and retrieve values.
resource mlzHubDeployment 'Microsoft.Resources/deployments@2021-04-01' existing = {
  scope: subscription(hubSubscriptionId)
  name: mlzHubDeploymentName
}
var mlzDeploymentVariables = mlzHubDeployment.properties.outputs
var hubResourceGroupName = mlzDeploymentVariables.hub.Value.resourceGroupName
var hubVirtualNetworkName = mlzDeploymentVariables.hub.Value.virtualNetworkName
var hubVirtualNetworkResourceId = mlzDeploymentVariables.hub.Value.virtualNetworkResourceId
var logAnalyticsWorkspaceResourceId = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value
var firewallPrivateIPAddress = mlzDeploymentVariables.firewallPrivateIPAddress.Value

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module spokeNetwork '../../modules/spokeNetwork.bicep' = {
  name: 'spokeNetwork'
  scope: az.resourceGroup(resourceGroup.name)
  params: {
    tags: tags

    logStorageAccountName: logStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId

    firewallPrivateIPAddress: firewallPrivateIPAddress

    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics

    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    subnetServiceEndpoints: subnetServiceEndpoints
  }
}

module workloadVirtualNetworkPeerings '../../modules/spokeNetworkPeering.bicep' = {
  name: take('${workloadName}--VNetPeerings', 64)
  params: {
    spokeName: workloadName
    spokeResourceGroupName: resourceGroup.name
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName

    hubVirtualNetworkName: hubVirtualNetworkName
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}

module hubToWorkloadVirtualNetworkPeering './modules/hubNetworkPeering.bicep' = {
  scope: subscription(hubSubscriptionId)
  name: 'hubToWorkloadVirtualNetworkPeering'
  params: {
    hubResourceGroupName: hubResourceGroupName
    hubVirtualNetworkName: hubVirtualNetworkName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
  }
}

output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
output virtualNetworkResourceId string = spokeNetwork.outputs.virtualNetworkResourceId
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output networkSecurityGroupResourceId string = spokeNetwork.outputs.networkSecurityGroupResourceId
