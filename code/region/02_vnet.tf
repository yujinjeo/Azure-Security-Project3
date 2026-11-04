resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.prefix}-hub-vnet-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.hub_cidrs
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${var.prefix}-spoke-vnet-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.spoke_cidrs
  tags                = var.tags
}
