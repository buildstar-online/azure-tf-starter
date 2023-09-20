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

## Instance Types and Limits

This project is tested using NVadsA10v5, NCasT4_v3, and NVv3 instances which utilize Nvidia A10, T4 and M60 GPUs. If you do not need a GPU, you are advised to consider Hetzner or Equinix who have better prices on CPU-only instances. Buildstar Online the following quota limits in west-europe:
 - 72 vCores for NVadsA10v5
 - 64 vCores for NCasT4_v3
 - 48 vCores for NVv3

### NVadsA10v5

- NVadsA10v5 series virtual machines are powered by NVIDIA A10 GPUs and AMD EPYC 74F3V(Milan) CPUs with a base frequency of 3.2 GHz, peak frequency of all cores of 4.0 GHz.

   | Instance Size            | GPUs   | GPU RAM | vCPUs | RAM (GiB) | Disk Size (GB) | Network (Gbps) |
   |   ---                    |  ---   |  ---    |    ---|        ---|             ---|             ---|
   | Standard_NV6ads_A10_v5   | 1/6    | 4       | 6     | 55        | 180            | 5              |
   | Standard_NV12ads_A10_v5  | 1/3    | 8       | 12    | 110       | 360            | 10             |
   | Standard_NV18ads_A10_v5  | 1/2    | 12      | 18    | 220       | 720            | 20             |
   | Standard_NV36ads_A10_v5  | 1      | 24      | 36    | 440       | 1440           | 40             |
   | Standard_NV72ads_A10_v5  | 2      | 48      | 72    | 880       | 2880           | 80             |

### NCasT4_v3

- NCasT4_v3 series virtual machines are powered by Nvidia Tesla T4 GPUs and AMD EPYC 7V12(Rome) CPUs. 

   | Instance Size         | GPUs | GPU RAM | vCPUs | RAM (GiB) | Disk Size (GB) | Network (Gbps) |
   |   ---                 |  --- |  ---    |    ---|        ---|             ---|             ---|
   | Standard_NC4as_T4_v3  | 1    | 16      | 4     | 28        | 180            | 8              |
   | Standard_NC8as_T4_v3  | 1    | 16      | 8     | 56        | 360            | 8              |
   | Standard_NC16as_T4_v3 | 1    | 16      | 16    | 110       | 360            | 8              |
   | Standard_NC64as_T4_v3 | 4    | 64      | 64    | 440       | 2880           | 32             |

### NVv3

- The NVv3 series virtual machines are powered by NVIDIA Tesla M60 GPUs and NVIDIA GRID technology with Intel E5-2690 v4 (Broadwell) CPUs and Intel Hyper-Threading Technology.

   | Instance Size       | GPUs | GPU RAM | vCPUs | RAM (GiB) | Disk Size (GB) | Network (Gbps) |
   |   ---               |  --- |  ---    |    ---|        ---|             ---|             ---|
   | Standard_NV12s_v3   | 1    | 8       | 12    | 112       | 320            | 6              |
   | Standard_NV24s_v3   | 2    | 16      | 24    | 224       | 640            | 12             |
   | Standard_NV48s_v3   | 4    | 32      | 48    | 448       | 1280           | 24             |

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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | n/a | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | n/a | `string` | `"Standard"` | no |
| <a name="input_admin_identity"></a> [admin\_identity](#input\_admin\_identity) | n/a | `string` | `"bradley"` | no |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | n/a | `list(string)` | n/a | yes |
| <a name="input_cr_sku"></a> [cr\_sku](#input\_cr\_sku) | n/a | `string` | `"Basic"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | `"dmeo"` | no |
| <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy) | n/a | `string` | `"Deallocate"` | no |
| <a name="input_github_username"></a> [github\_username](#input\_github\_username) | n/a | `string` | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | n/a | `string` | `"azurespot"` | no |
| <a name="input_kv_sku_name"></a> [kv\_sku\_name](#input\_kv\_sku\_name) | n/a | `string` | `"standard"` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"westeurope"` | no |
| <a name="input_log_storage_tier"></a> [log\_storage\_tier](#input\_log\_storage\_tier) | n/a | `string` | `"Hot"` | no |
| <a name="input_max_bid_price"></a> [max\_bid\_price](#input\_max\_bid\_price) | n/a | `string` | n/a | yes |
| <a name="input_overprovision"></a> [overprovision](#input\_overprovision) | n/a | `bool` | `false` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | n/a | `string` | `"Spot"` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | n/a | `string` | `"demo-rg"` | no |
| <a name="input_scale_in_force_deletion_enabled"></a> [scale\_in\_force\_deletion\_enabled](#input\_scale\_in\_force\_deletion\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_scale_in_rule"></a> [scale\_in\_rule](#input\_scale\_in\_rule) | n/a | `string` | `"NewestVM"` | no |
| <a name="input_scale_set_name"></a> [scale\_set\_name](#input\_scale\_set\_name) | n/a | `string` | `"scale-set"` | no |
| <a name="input_spot_restore_enabled"></a> [spot\_restore\_enabled](#input\_spot\_restore\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_spot_restore_timeout"></a> [spot\_restore\_timeout](#input\_spot\_restore\_timeout) | n/a | `string` | `"PT1H30M"` | no |
| <a name="input_ultra_ssd_enabled"></a> [ultra\_ssd\_enabled](#input\_ultra\_ssd\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_user_data_path"></a> [user\_data\_path](#input\_user\_data\_path) | n/a | `string` | `"./NVadsA10v5.yaml"` | no |
| <a name="input_username"></a> [username](#input\_username) | n/a | `string` | n/a | yes |
| <a name="input_vm_instances"></a> [vm\_instances](#input\_vm\_instances) | n/a | `number` | `1` | no |
| <a name="input_vm_network_interface"></a> [vm\_network\_interface](#input\_vm\_network\_interface) | n/a | `string` | `"vm-nic"` | no |
| <a name="input_vm_os_disk_size_gb"></a> [vm\_os\_disk\_size\_gb](#input\_vm\_os\_disk\_size\_gb) | n/a | `number` | `64` | no |
| <a name="input_vm_sku"></a> [vm\_sku](#input\_vm\_sku) | n/a | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
