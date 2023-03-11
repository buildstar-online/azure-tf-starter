terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.4.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0.4"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "example-tf-state"
    storage_account_name = "examplertfstatebucket"
    container_name       = "exampletfstate"
    key                  = "example.terraform.tfstate"
  }
}


provider "tls" {
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}

provider "azuread" {
}

provider "random" {
}

provider "time" {
}
