
variable "environment" {
  type    = string
  default = "dmeo"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group" {
  type    = string
  default = "demo-rg"
}

variable "admin_identity" {
  type    = string
  default = "bradley"
}

variable "allowed_ips" {
  type = list(string)
}

variable "cr_sku" {
  type    = string
  default = "Basic"
}

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "account_replication_type" {
  type    = string
  default = "LRS"
}

variable "kv_sku_name" {
  type    = string
  default = "standard"
}

variable "log_storage_tier" {
  type    = string
  default = "Hot"
}

variable "scale_set_name" {
  type    = string
  default = "scale-set"
}

variable "vm_sku" {
  type    = string
}

variable "username" {
  type    = string
}

variable "github_username" {
  type    = string
}

variable "hostname" {
  type    = string
  default = "azurespot"
}

variable "vm_instances" {
  type    = number
  default = 1
}

variable "priority" {
  type    = string
  default = "Spot"
}

variable "spot_restore_enabled" {
  type    = bool
  default = true
}

variable "spot_restore_timeout" {
  type    = string
  default = "PT1H30M"
}

variable "eviction_policy" {
  type    = string
  default = "Deallocate"
}

variable "max_bid_price" {
  type    = string
}

variable "overprovision" {
  type    = bool
  default = false
}

variable "ultra_ssd_enabled" {
  type    = bool
  default = false
}

variable "scale_in_rule" {
  type    = string
  default = "NewestVM"
}

variable "scale_in_force_deletion_enabled" {
  type    = bool
  default = true
}

variable "user_data_path" {
  type    = string
  default = "./NVadsA10v5.yaml"
}

variable "vm_network_interface" {
  type    = string
  default = "vm-nic"
}

variable "vm_os_disk_size_gb" {
  type    = number
  default = 64
}
