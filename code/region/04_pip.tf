resource "azurerm_public_ip" "mgmt_pip" {
  name                = "${var.prefix}-mgmt-pip-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.prefix}-appgw-pip-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "vpn_pip" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "${var.prefix}-vpn-pip-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

