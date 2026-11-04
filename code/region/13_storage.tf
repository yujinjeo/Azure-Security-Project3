locals {
  storage_account_name = "st073${var.region_code}${var.storage_name_suffix}"
}

resource "azurerm_storage_account" "app" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "appdata" {
  name                  = "appdata"
  storage_account_id    = azurerm_storage_account.app.id
  container_access_type = "private"

  
}
