
resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "${var.prefix}-vpngw-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type       = "Vpn"
  vpn_type   = "RouteBased"
  sku        = "VpnGw2AZ"
  generation = "Generation2"

  active_active = false
  bgp_enabled   = false

  ip_configuration {
    name                          = "vpngw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_pip[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet[0].id
  }

  tags = var.tags
}

resource "azurerm_local_network_gateway" "onprem" {
  count = var.create_onprem_connection ? 1 : 0

  name                = "${var.prefix}-lng-bluemax"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  gateway_address     = var.onprem_gateway_public_ip
  address_space       = var.onprem_address_spaces
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "onprem" {
  count = var.create_onprem_connection ? 1 : 0

  name                = "${var.prefix}-s2s-bluemax"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem[0].id
  shared_key                 = "secui098!"

  ipsec_policy {
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    dh_group         = "DHGroup2048"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_lifetime      = 27000
    sa_datasize      = 102400000
  }

  tags = var.tags
}
