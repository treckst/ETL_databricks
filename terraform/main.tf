provider "azurerm" {
  features {}
  subscription_id = var.SUBSCRIPTION_ID
}

resource "random_string" "random" {
  length  = 4
  upper = false
  special = false
}

resource "azurerm_resource_group" "bdcc" {
  name     = "rg-${var.ENV}${var.LOCATION}${random_string.random.result}"
  location = var.LOCATION
}

resource "azurerm_storage_account" "bdcc" {
  name                     = "st${var.ENV}${var.LOCATION}${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.bdcc.name
  location                 = var.LOCATION
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bdcc" {
  depends_on         = [azurerm_storage_account.bdcc]
  name               = "data"
  storage_account_id = azurerm_storage_account.bdcc.id
}

resource "azurerm_databricks_workspace" "bdcc" {
  name                = "dbw-${var.ENV}${var.LOCATION}${random_string.random.result}"
  resource_group_name = azurerm_resource_group.bdcc.name
  location            = azurerm_resource_group.bdcc.location
  sku                 = "premium"
}

output "resource_group_name" {
  value=azurerm_resource_group.bdcc.name
}