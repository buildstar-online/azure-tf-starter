<h1 align=center>
   Azure Cloud Starter Project
</h1>

<p align="center">
  <img width="64" src="https://icons-for-free.com/iconfiles/png/512/terraform-1331550893634583795.png">
  <img width="64" src="https://icons-for-free.com/iconfiles/png/512/Azure-1329545813777356941.png">
<p>

<p align=center>
Create and manage the basic resources needed for a new Azure project <br> 
  using Terraform and Github Actions.<br>
</p>
<br>

## Getting Started

You will need to install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and log-in. I would also reccommend you install a secrets or password manager to hold the credentials we will create. I'll be using a free [Bitwarden](https://bitwarden.com/pricing/) account along with their [bitwarden-cli](https://bitwarden.com/help/cli/) to manage my secrets for this demonstration.

- Install Azure CLI

   ```bash
   brew update && \
   brew install azure-cli
   ```

- Install Bitwarden CLI

   ```bash
   brew install bitwarden-cli
   ```

- Login

   ```bash
   # Authorize the Azure CLI
   az login
   ```

___

## IAM Setup

You need to create a service account to represent your digital self and use that to run terraform locally. In production, a unique service account should be created for running and applying the terraform jobs,and it should create smaller accounts at instantiation to run the infra it provisions. 

> 'Owner' level access is required because we need to create role assignments. This may potentially be scoped down to 'User Access Administrator' + 'Contributor'

1. Create your service principle and then add the resulting data to KeePassXC / Bitwarden for now. You will need it again multiple times.

    ```bash
    SUBSCRIPTION=$(az account show --query id --output tsv)
    SP_NAME="myserviceaccount"

    az ad sp create-for-rbac --sdk-auth \
      --display-name="${SP_NAME}" \
      --role="Owner" \
      --scopes="/subscriptions/$SUBSCRIPTION"
    ```

2. Setup the Azure Active Directory Permissions for your Service Principle. This is required in order to set AD roles in terraform.

   - Login to https://portal.azure.com/
  
   -  Navigate to `Azure Active Directory`
  
   - Select `Roles and administrators` from the left-side menu
  
   - Click `Application administrator`
  
   - Click `Add Assignments`
  
   - Search for your service accounts name
  
   - Repeat for `Application Developer` Role.
   

## Creating the State Bucket

- Before we start you should login to Azure again, but now as the service principle we created. We will use this account to create the terraform state bucket. That way, only the service-principle will have access to it.

   ```bash
   az login --service-principal \
      --username $(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
      --password $(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
      --tenant $(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value')
   ```

- Now Create the Terraform state bucket

    ```bash
    export SUBSCRIPTION=$(az account show --query id --output tsv)    
    export KIND="StorageV2"
    export LOCATION="westeurope"
    export RG_NAME="example-tf-state"
    export STORAGE_NAME="examplertfstatebucket"
    export STORAGE_SKU="Standard_RAGRS"
    export CONTAINER_NAME="exampletfstate"

    az group create \
      -l="${LOCATION}" \
      -n="${RG_NAME}"

    az storage account create \
      --name="${STORAGE_NAME}" \
      --resource-group="${RG_NAME}" \
      --location="${LOCATION}" \
      --sku="${STORAGE_SKU}" \
      --kind="${KIND}"

    az storage account encryption-scope create \
      --account-name="${STORAGE_NAME}"  \
      --key-source Microsoft.Storage \
      --name="tfencryption"\
      --resource-group="${RG_NAME}" \
      --subscription="${SUBSCRIPTION}"

    az storage container create \
        --name="${CONTAINER_NAME}" \
        --account-name="${STORAGE_NAME}" \
        --resource-group="${RG_NAME}" \
        --default-encryption-scope="tfencryption" \
        --prevent-encryption-scope-override="true" \
        --auth-mode="login" \
        --fail-on-exist \
        --public-access="off"
    ```
    
## Initializing your Terraform Project

- Add your state-bucket details to the `providers.tf` file if you made any customisations

   ```hcl
   backend "azurerm" {
      resource_group_name  = "example-tf-state"
      storage_account_name = "examplertfstatebucket"
      container_name       = "exampletfstate"
      key                  = "example.terraform.tfstate"
   }
   ```

- Add your ip-address and personal azure account's clientID to the `environment-base.tf` file under the `Firewall` header.

   ```hcl
   # Firewall
   allowed_ips = ["192.168.50.1"]
   admin_users = ["clientId-goes-here"]
   ```


- Initialize the terraform project

   ```bash
   docker run --platform linux/amd64 -it \
      -e ARM_CLIENT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
      -e ARM_CLIENT_SECRET=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
      -e ARM_SUBSCRIPTION_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="subscriptionId") |.value') \
      -e ARM_TENANT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value') \
      -v $(pwd):/terraform -w /terraform \
      hashicorp/terraform init
   ```

- Plan / Apply resources

   ```bash
   docker run --platform linux/amd64 -it \
      -e ARM_CLIENT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
      -e ARM_CLIENT_SECRET=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
      -e ARM_SUBSCRIPTION_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="subscriptionId") |.value') \
      -e ARM_TENANT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value') \
      -v $(pwd):/terraform -w /terraform \
      hashicorp/terraform apply
   ```

- Destroy Resources

   ```bash
   docker run --platform linux/amd64 -it \
      -e ARM_CLIENT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
      -e ARM_CLIENT_SECRET=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
      -e ARM_SUBSCRIPTION_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="subscriptionId") |.value') \
      -e ARM_TENANT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value') \
      -v $(pwd):/terraform -w /terraform \
      hashicorp/terraform destroy
   ```
   

- Cleanup

   ```bash
   # ToDo
   ```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~>2.36.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~>3.47.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~>3.4.3 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~>0.9.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~>4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~>3.47.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_environment-base"></a> [environment-base](#module\_environment-base) | github.com/cloudymax/modules-azure-tf-base | n/a |
| <a name="module_scale-set"></a> [scale-set](#module\_scale-set) | github.com/cloudymax/modules-azure-tf-scale-set | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
