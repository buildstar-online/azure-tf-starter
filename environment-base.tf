data "azurerm_client_config" "current" {
}

module "environment-base" {

  source = "github.com/cloudymax/modules-azure-tf-base"

  # Project settings
  environment      = "demo"
  location         = "westeurope"
  resource_group   = "demo-rg"
  subscription_id  = data.azurerm_client_config.current.subscription_id
  tenant_id        = data.azurerm_client_config.current.tenant_id
  runner_object_id = data.azurerm_client_config.current.object_id

  # Identities
  admin_identity = "admin-identity"

  # Virtual Network
  vnet_name          = "demo-net"
  vnet_address_space = ["10.0.0.0/16"]
  vnet_subnet_name   = "demo-subnet"
  subnet_prefixes    = ["10.0.1.0/16"]

  # Container Registry
  cr_name = "demo-registry"
  cr_sku  = "basic"

  # Storage
  storage_acct_name        = "demo-bucket"
  account_tier             = "Standard"
  account_replication_type = "LBS"
  log_storage_tier         = "Hot"

  #KeyVault
  kv_name    = "demo-kv"
  kv_sku_ame = "standard"

  # Firewall
  allowed_ips = ["192.168.50.1"]
  admin_users = ["clientId-goes-here"]
}
