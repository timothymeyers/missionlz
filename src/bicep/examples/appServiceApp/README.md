# App Service App Docker Example

Deploys a web accessible basic Linux container using Azure App Services with the following features:

* Utilizes Azure App Service deployment slots - a prod and staging slot to enable blue/green deployments
* Utilizes continous deployment from Azure Container Registry to the staging slot

Read on to understand what this example does, and when you're ready, collect all of the pre-requisites, then deploy the example.

## What this example does

### Deploys an App Service Docker App (Linux)

The docs on Azure App Service Web Apps: <https://docs.microsoft.com/en-us/azure/app-service/>.  This sample shows how to deploy using Bicep and utilizes the shared file variable pattern to support the deployment.  By default, this template will deploy resources into standard default MLZ subscriptions and resource groups.  

## Pre-requisites

1. A Mission LZ deployment (a deployment of mlz.bicep)
2. The outputs from a deployment of mlz.bicep (./src/bicep/examples/deploymentVariables.json).
3. Update ./src/bicep/examples/deploymentVariables.json to include values for Azure Key Vault and Azure App Service Plan.  See dependencies for samples.

See below for information on how to create the appropriate deployment variables file for use with this template.

### Template Parameters

Template Parameters | Description
-----------------------| -----------
containerBaseImageName | The base container name of the container to be deployed.  For example, "nginx'.  The image specified must be avaliable in container registry.  If not specified, the name will default to the MLZ default naming pattern.  
containerImageTag | The tag applied to the container hosted in the container registry which should be deployed.  If no tag is specified, then 'latest' is used as default.

### Generate MLZ Variable File (deploymentVariables.json)

For instructions on generating 'deploymentVariables.json' using both Azure PowerShell and Azure CLI, please see the [README at the root of the examples folder](..\README.md).

Place the resulting 'deploymentVariables.json' file within the ./src/bicep/examples folder.

### Update MLZ Variable File (deploymentVariables.json)

This deployment depends on other MLZ example deployments, specifically:

* Azure Container Registry: Deploy template found in ./src/bicep/examples/containerRegistry
* Azure Key Vault:  Deploy template found in ./src/bicep/examples/keyVault
  * Add Secrets: Obtain values from Azure Container Registry 'Access Keys' blade in Azure portal
    * dockerRegistryUrl
    * dockerRegistryUsername
    * dockerRegistryPassword
* Azure App Service Plan:  Deploy template found in ./src/bicep/examples/appServicePlan

After deploying the container registry, key vault, and app service plan, update deploymentVariables.json with the apprpriate values from each deployment.  Sample shown below:

```json
{
  "mlzResourcePrefix": {
    "Type": "String",
    "Value": "contoso"
  },
  "mlzKeyVault": {
    "Type":"Object",
    "Value": {
      "keyVaultName": "contoso-eastus-kv",
      "keyVaultResourceGroup": "contoso-sharedServices",
      "keyVaultSubid": "ddf87969-a498-4676-a488-1932fbc5a306"
    }
  },
  "mlzAppServicePlan": {
    "Type":"Object",
    "Value": {
      "appServicePlanName": "contoso-asp",
      "appServicePlanResourceGroup": "contoso-sharedServices",
      "appServicePlanSubId": "ddf87969-a498-4676-a488-1932fbc5a306"
    }
  },
  "mlzContainerRegistry": {
    "Type":"Object",
    "Value": {
      "containerRegistryName": "contosoeastusacr",
      "containerRegistryResourceGroup": "contoso-sharedServices",
      "containerRegistrySubId": "ddf87969-a498-4676-a488-1932fbc5a306"
    }
  },
  "firewallPrivateIPAddress": {
    "Type": "String",
    "Value": "10.0.100.4"
  },
}
```

### Deploy Container Image to Azure Container Registry

The container deployed here is the container that will be deployed to Azure App Service.  See the references at the bottom of this readme for detailed information on deploying custom docker containers. Shown below are the commands to upload and tag a generic image simply to show the process of uploading a container image for use with this template.  

Please substitue relevant values in place of the values shown below.

```DockerCLI
docker pull nginx
docker login contosoeastusacr.azurecr.io
docker tag nginx contosoeastusacr.azurecr.io/nginx
docker push contosoeastusacr.azurecr.io/nginx
```

### Deploying App Service Docker App

Connect to the appropriate Azure Environment and set appropriate context, see getting started with Azure PowerShell for help if needed.  The commands below assume you are deploying in Azure Commercial and show the entire process from deploying MLZ and then adding an Azure App Service Plan post-deployment.

```PowerShell
cd .\src\bicep
Connect-AzAccount
New-AzSubscriptionDeployment -Name contoso -TemplateFile .\mlz.bicep -resourcePrefix 'contoso' -Location 'eastus'
cd .\examples
(Get-AzSubscriptionDeployment -Name contoso).outputs | ConvertTo-Json | Out-File -FilePath .\deploymentVariables.json
cd .\AppServicePlan
/*
At this point:  deploy Azure Key Vault, Azure Container Registry, and Azure App Service Plan and then update deploymentVariables.json as described above.  After updating the deploymentVariables.json file, proceed to next command.  
*/
New-AzSubscriptionDeployment -DeploymentName deployAppServiceApp -TemplateFile .\appServiceApp.bicep -Location 'eastus'
```

```Azure CLI
az login
cd src/bicep
az deployment sub create -n contoso -f mlz.bicep -l eastus --parameters resourcePrefix=contoso
cd examples
az deployment sub show -n contoso --query properties.outputs >> ./deploymentVariables.json
cd appServicePlan
/*
At this point:  deploy Azure Key Vault, Azure Container Registry, and Azure App Service Plan and then update deploymentVariables.json as described above.  After updating the deploymentVariables.json file, proceed to next command.  
*/
az deployment sub create -n deployAppServiceApp -f appServiceApp.bicep -l eastus
```

### References

* [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
* [Deploy customer Docker containers in App Service](https://docs.microsoft.com/en-us/azure/app-service/quickstart-custom-container)
* [Getting started with the Docker CLI](https://docs.docker.com/get-started/)
* [Bicep Shared Variable File Pattern](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file)
