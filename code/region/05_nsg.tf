# ============================================================
# MGMT NSG
# ============================================================
resource "azurerm_network_security_group" "mgmt_nsg" {
  name                = "${var.prefix}-mgmt-nsg-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "mgmt_ssh" {
  name                        = "allow-ssh-admin"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.mgmt_nsg.name
}

# ============================================================
# WEB NSG
# ============================================================
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.prefix}-web-nsg-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "web_http" {
  name                        = "allow-http-from-appgw"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.appgw_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}

resource "azurerm_network_security_rule" "web_ssh" {
  name                        = "allow-ssh-from-mgmt"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes       = ["1.220.76.4" , var.mgmt_subnet_cidr]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
}

# ============================================================
# WAS NSG
# ============================================================
resource "azurerm_network_security_group" "was_nsg" {
  name                = "${var.prefix}-was-nsg-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "was_http" {
  name                        = "allow-http-from-appgw"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.appgw_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.was_nsg.name
}

resource "azurerm_network_security_rule" "was_ssh" {
  name                        = "allow-ssh-from-mgmt"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes       = ["1.220.76.4", var.mgmt_subnet_cidr]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.was_nsg.name
}

# ============================================================
# DB NSG
# ============================================================
resource "azurerm_network_security_group" "db_nsg" {
  #count = var.create_database ? 1 : 0

  name                = "${var.prefix}-db-nsg-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "db_mysql_was" {
  #count = var.create_database ? 1 : 0

  name                        = "allow-mysql-from-was"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = var.was_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

resource "azurerm_network_security_rule" "db_mysql_mgmt" {
  #count = var.create_database ? 1 : 0

  name                        = "allow-mysql-from-mgmt"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = var.mgmt_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

resource "azurerm_network_security_rule" "db_mysql_onprem" {
  #count = var.create_database && var.create_onprem_connection ? 1 : 0

  name                        = "allow-mysql-from-onprem"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefixes     = ["1.220.76.4/32", "192.168.0.0/16"]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

