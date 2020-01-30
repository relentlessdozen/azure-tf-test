# Variables

variable "location" {
  type    = string
  default = "East US"
}

# Configure Azure Service Provider
provider "azurerm" {
  # select version 
  version = "=1.38.0"
}

# Create frontend-rg resource group
resource "azurerm_resource_group" "frontend-rg" {
  name     = "dev-frontend"
  location = var.location
}

# Create backend-rg resource group
resource "azurerm_resource_group" "backend-rg" {
  name     = "dev-backend"
  location = var.location
}

resource "azurerm_storage_account" "sadevbackend" {
  name                     = "sadevbackend"
  resource_group_name      = azurerm_resource_group.backend-rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate-ct" {
  name                 = "terraform-state"
  storage_account_name = azurerm_storage_account.sadevbackend.name
}

data "azurerm_storage_account_sas" "state" {
  connection_string = azurerm_storage_account.sadevbackend.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "17520h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
  }
}

# Create a v-net with the frontend-rg for the dev environment
resource "azurerm_virtual_network" "vnet1" {
  name                = "devnet1"
  resource_group_name = azurerm_resource_group.frontend-rg.name
  location            = azurerm_resource_group.frontend-rg.location
  address_space       = ["10.0.0.0/16"]
}

# Provisioner


# OUTPUT

output "storage_account_name" {
  value = azurerm_storage_account.sadevbackend.name
}

output "resource_group_name" {
  value = azurerm_resource_group.backend-rg.name
}

output "sas_token" {
  value = data.azurerm_storage_account_sas.state.sas
}
