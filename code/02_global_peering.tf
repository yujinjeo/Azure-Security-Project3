# ============================================================
# Korea Hub <-> Japan Hub Global VNet Peering
# ============================================================
resource "azurerm_virtual_network_peering" "korea_to_japan" {
  name                      = "${local.prefix}-krc-hub-to-jpe-hub"
  resource_group_name       = module.korea.rg_name
  virtual_network_name      = module.korea.hub_vnet_name
  remote_virtual_network_id = module.japan.hub_vnet_id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "japan_to_korea" {
  name                      = "${local.prefix}-jpe-hub-to-krc-hub"
  resource_group_name       = module.japan.rg_name
  virtual_network_name      = module.japan.hub_vnet_name
  remote_virtual_network_id = module.korea.hub_vnet_id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "korea_hub_to_japan_spoke" {
  name                      = "${local.prefix}-krc-hub-to-jpe-spoke"
  resource_group_name       = module.korea.rg_name
  virtual_network_name      = module.korea.hub_vnet_name
  remote_virtual_network_id = module.japan.spoke_vnet_id

  allow_forwarded_traffic = true
  allow_gateway_transit   = true
}

resource "azurerm_virtual_network_peering" "japan_spoke_to_korea_hub" {
  name                      = "${local.prefix}-jpe-spoke-to-krc-hub"
  resource_group_name       = module.japan.rg_name
  virtual_network_name      = module.japan.spoke_vnet_name
  remote_virtual_network_id = module.korea.hub_vnet_id

  allow_forwarded_traffic = true
  use_remote_gateways     = true
}
