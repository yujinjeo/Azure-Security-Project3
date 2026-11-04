resource "azurerm_dns_zone" "public" {
  #count = var.create_public_dns_zone ? 1 : 0

  name                = var.dns_name
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}
