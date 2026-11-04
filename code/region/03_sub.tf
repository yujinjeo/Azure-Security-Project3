resource "azurerm_subnet" "gateway_subnet" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

resource "azurerm_subnet" "mgmt_subnet" {
  name                            = "${var.prefix}-mgmt-subnet-${var.region_code}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.hub_vnet.name
  address_prefixes                = [var.mgmt_subnet_cidr]
  default_outbound_access_enabled = true
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "${var.prefix}-appgw-subnet-${var.region_code}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

resource "azurerm_subnet" "web_subnet" {
  name                            = "${var.prefix}-web-subnet-${var.region_code}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.spoke_vnet.name
  address_prefixes                = [var.web_subnet_cidr]
  default_outbound_access_enabled = true
}

resource "azurerm_subnet" "was_subnet" {
  name                            = "${var.prefix}-was-subnet-${var.region_code}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.spoke_vnet.name
  address_prefixes                = [var.was_subnet_cidr]
  default_outbound_access_enabled = true
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "${var.prefix}-db-subnet-${var.region_code}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = [var.db_subnet_cidr]

  delegation {
    name = "mysql-flexible-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}


resource "azurerm_subnet" "proxy_subnet" {
  name                            = "${var.prefix}-proxy-subnet-${var.region_code}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.spoke_vnet.name
  address_prefixes                = [var.proxy_subnet_cidr]

  
  
  delegation {
    name = "aci-delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

