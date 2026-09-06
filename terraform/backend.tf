terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate27634"
    container_name       = "tfstate"
    key                  = "etl_streaming.tfstate"
  }
}
