resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt_subnet.id
  network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "was" {
  subnet_id                 = azurerm_subnet.was_subnet.id
  network_security_group_id = azurerm_network_security_group.was_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "proxy" {
  subnet_id = azurerm_subnet.proxy_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}