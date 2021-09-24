param builtInAssignment string = ''
param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceGroupName string
param operationsSubscriptionId string

// Creating a symbolic name for an existing resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(operationsSubscriptionId, logAnalyticsWorkspaceResourceGroupName)
}

var policyDefinitionID = {
  NIST: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f'
    parameters: json(replace(loadTextContent('policies/NIST-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }  
  IL5: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
    parameters: json(replace(loadTextContent('policies/IL5-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.id))
  }
  CMMC: {
    id: '/providers/Microsoft.Authorization/policySetDefinitions/b5629c75-5c77-4422-87b9-2509e680f8de'
    parameters: json(replace(loadTextContent('policies/CMMC-policyAssignmentParameters.json'),'<LAWORKSPACE>', logAnalyticsWorkspace.properties.customerId))
  }  
}

var modifiedAssignment = ( environment().name =~ 'AzureCloud' && builtInAssignment =~ 'IL5' ? 'NIST' : builtInAssignment )
var assignmentName = '${modifiedAssignment} ${resourceGroup().name}'
var agentVmmsAssignmentName = 'Deploy VMSS Agents ${resourceGroup().name}'
var agentVmAssignmentName = 'Deploy VM Agents ${resourceGroup().name}'
var contributorRoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource assignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = if (!empty(modifiedAssignment)){
  name: assignmentName
  location: resourceGroup().location
  properties: {
      policyDefinitionId: policyDefinitionID[modifiedAssignment].id
      parameters: policyDefinitionID[modifiedAssignment].parameters
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource vmmsAgentAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: agentVmmsAssignmentName
  location: resourceGroup().location
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/75714362-cae7-409e-9b99-a8e5075b7fad'
    parameters: {
      logAnalytics_1: {
        value: logAnalyticsWorkspace.id
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource vmAgentAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: agentVmAssignmentName
  location: resourceGroup().location
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/55f3eceb-5573-4f18-9695-226972c6d74a'
    parameters: {
      logAnalytics_1: {
        value: logAnalyticsWorkspace.id
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource policyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId,assignmentName)
  scope: resourceGroup()
  dependsOn: [
    assignment
  ]
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: assignment.identity.principalId
    principalType: 'ServicePrincipal'
    }
  }

resource vmmsPolicyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId,agentVmmsAssignmentName)
  scope: resourceGroup()
  dependsOn: [
    vmmsAgentAssignment
    policyRoleAssignment
  ]
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: vmmsAgentAssignment.identity.principalId
    principalType: 'ServicePrincipal'
    }
  }

resource vmPolicyRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(contributorRoleDefinitionId,agentVmAssignmentName)
  scope: resourceGroup()
  dependsOn: [
    vmAgentAssignment
    vmmsPolicyRoleAssignment
  ]
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: vmAgentAssignment.identity.principalId
    principalType: 'ServicePrincipal'
    }
  }
