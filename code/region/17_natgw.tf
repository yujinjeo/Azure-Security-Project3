resource "azurerm_public_ip" "natpip" {
    name = "${var.prefix}-natpip-${var.region_code}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    allocation_method = "Static"
}

resource "azurerm_nat_gateway" "natgw" {
    name = "${var.prefix}-natgw-${var.region_code}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    sku_name = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_asso" {
    nat_gateway_id = azurerm_nat_gateway.natgw.id
    public_ip_address_id = azurerm_public_ip.natpip.id
}