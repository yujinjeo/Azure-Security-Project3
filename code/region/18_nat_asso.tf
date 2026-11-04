resource "azurerm_subnet_nat_gateway_association" "nat_was_asso" {
    subnet_id = azurerm_subnet.was_subnet.id
    nat_gateway_id = azurerm_nat_gateway.natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_web_asso" {
    subnet_id = azurerm_subnet.web_subnet.id
    nat_gateway_id = azurerm_nat_gateway.natgw.id
}

