data "azurerm_client_config" "current" {
}

locals {
  # Project Options
  environment    = "demo"
  location       = "westeurope"
  resource_group = "demo-rg"

  # Security Options
  admin_identity = "bradley"
  admin_users    = ["${data.azurerm_client_config.current.client_id}"]
}

module "environment-base" {

  source = "github.com/cloudymax/modules-azure-tf-base"

  # Project settings
  environment      = local.environment
  location         = local.location
  resource_group   = local.resource_group
  subscription_id  = data.azurerm_client_config.current.subscription_id
  tenant_id        = data.azurerm_client_config.current.tenant_id
  runner_object_id = data.azurerm_client_config.current.object_id

  # Identities
  admin_identity = local.admin_identity

  # Virtual Network
  vnet_name          = "v-net"
  vnet_address_space = ["192.168.0.0/16"]

  # Container Registry
  cr_sku                        = "Basic"
  public_network_access_enabled = true

  # Storage
  account_tier             = "Standard"
  account_replication_type = "LRS"
  log_storage_tier         = "Hot"

  #KeyVault
  kv_sku_name = "standard"

  # Firewall
  allowed_ips = ["${var.allowed_ips}"]
  admin_users = local.admin_users

}

module "scale-set" {

  source = "github.com/cloudymax/modules-azure-tf-scale-set"

  # Project settings
  environment    = local.environment
  location       = local.location
  resource_group = local.resource_group
  allowed_ips    = ["${var.allowed_ips}"]

  # Scale Set VM settings
  scale_set_name                  = "scale-set"
  vm_sku                          = "Standard_NV6ads_A10_v5"
  vm_instances                    = 1
  priority                        = "Spot"
  spot_restore_enabled            = true
  spot_restore_timeout            = "PT1H30M"
  eviction_policy                 = "Deallocate"
  max_bid_price                   = "0.24"
  overprovision                   = false
  ultra_ssd_enabled               = false
  scale_in_rule                   = "NewestVM"
  scale_in_force_deletion_enabled = true
  cloud_init_path                 = "cloud-init.txt"
  vm_admin_username               = local.admin_identity
  vm_name_prefix                  = "${local.environment}-"
  vm_network_interface            = "vm-nic"

  # Network options
  vnet_name        = module.environment-base.vnet_name
  vnet_subnet_name = "scale-set-subnet"
  subnet_prefixes  = ["192.168.1.0/24"]

  # OS Disk options
  vm_os_disk_caching                   = "ReadWrite"
  vm_os_storage_account_type           = "Premium_LRS"
  vm_os_disk_size_gb                   = 32
  vm_os_disk_write_accelerator_enabled = false

  # Storage Disk options
  vm_data_disk_caching                   = "None"
  vm_data_storage_account_type           = "PremiumV2_LRS"
  vm_data_disk_size_gb                   = "32"
  vm_data_disk_write_accelerator_enabled = false
  vm_data_disk_create_option             = "Empty"

  # OS Images settings
  vm_source_image_publisher = "Canonical"
  vm_source_image_offer     = "0001-com-ubuntu-server-focal-daily"
  vm_source_image_sku       = "20_04-daily-lts-gen2"
  vm_source_image_verson    = "20.04.202303090"

  # Storage account
  storage_account_url = module.environment-base.storage_account.primary_blob_endpoint

  # Key Vault
  keyvault_id = module.environment-base.kv_id

  # Managed Identity
  admin_users = ["${module.environment-base.managed_identity_id}"]

  # Network Settings
  vm_net_iface_name                          = "vm-nic"
  vm_net_iface_ipconfig_name                 = "vm-nic-config"
  vm_net_iface_private_ip_address_allocation = "Dynamic"

  depends_on = [
    module.environment-base
  ]
}

