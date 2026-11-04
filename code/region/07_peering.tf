resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "${var.prefix}-hub-to-spoke-${var.region_code}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id

  allow_forwarded_traffic = true
  allow_gateway_transit   = var.enable_vpn_gateway

  depends_on = [azurerm_virtual_network_gateway.vpn]
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "${var.prefix}-spoke-to-hub-${var.region_code}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id

  allow_forwarded_traffic = true
  use_remote_gateways     = var.enable_vpn_gateway

  depends_on = [azurerm_virtual_network_gateway.vpn]

}
