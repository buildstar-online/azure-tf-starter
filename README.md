# Getting Started

1. Install Azure CLI

   ```bash
   brew update && \
   brew install azure-cli
   ```

2. Install Bitwarden CLI

   ```bash
   brew install bitwarden-cli
   ```

3. Login

   ```bash
   # Authorize the Azure CLI
   az login
   ```

4. Create your service principle

  - Create a service account to represent your digital self and use that to run terraform locally.

  - In production, a unique service account should be created for running and applying the terraform jobs,
and it should create smaller accounts at instantiation to run the infra it provisions.

  - 'Owner' level access is required because we need to create role assignments. This may potentially be
scoped down to 'User Access Administrator' + 'Contributor'

      ```bash
      SUBSCRIPTION=$(az account show --query id --output tsv)
      SP_NAME="myserviceaccount"

      az ad sp create-for-rbac --sdk-auth \
        --display-name="${SP_NAME}" \
        --role="Owner" \
        --scopes="/subscriptions/$SUBSCRIPTION"
      ```

  - Add the resulting data to KeePassXC / Bitwarden for now. You will need it again multiple times.

___


5. Set Azure Active Directory Permissions

This is required in order to set AD roles in terraform.

  - Login to https://portal.azure.com/
  - Navigate to `Azure Active Directory`
  - Select `Roles and administrators` from the left-side menu
  - Click `Application administrator`
  - Click `Add Assignments`
  - Search for your service accounts name
  - Repeat for `Application Developer` Role.

___

6. Log-in as the service principle or user.

- we will use this account to create the terraform state bucket.

```bash
  az login --service-principal \
    --username $(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
    --password $(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
    --tenant $(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value')
```

____

7. Create the Terraform state bucket

  - All Azure Storage Accounts are encrypted by default using Microsoft Managed Keys
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
___

8. Add your state-bucket details to the `providers.tf` file if you made any customisations

```hcl
  backend "azurerm" {
    resource_group_name  = "example-tf-state"
    storage_account_name = "examplertfstatebucket"
    container_name       = "exampletfstate"
    key                  = "example.terraform.tfstate"
  }
```
___

9. Add your ip-address and user-account's clientID to the `environment-base.tf` file

___

10. Initialize the terraform project

```bash
docker run --platform linux/amd64 -it \
-e ARM_CLIENT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
-e ARM_CLIENT_SECRET=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
-e ARM_SUBSCRIPTION_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="subscriptionId") |.value') \
-e ARM_TENANT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value') \
-v $(pwd):/terraform -w /terraform \
hashicorp/terraform init
```

9. Plan / Apply resources

```bash
docker run --platform linux/amd64 -it \
-e ARM_CLIENT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientId") |.value') \
-e ARM_CLIENT_SECRET=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="clientSecret") |.value') \
-e ARM_SUBSCRIPTION_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="subscriptionId") |.value') \
-e ARM_TENANT_ID=$(bw get item admin-robot |jq -r '.fields[] |select(.name=="tenantId") |.value') \
-v $(pwd):/terraform -w /terraform \
hashicorp/terraform apply
```

