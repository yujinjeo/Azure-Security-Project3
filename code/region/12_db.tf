locals {
  db_name = "team3db"
  db_sku  = "GP_Standard_D2ds_v4"

  db_server_id   = try(azurerm_mysql_flexible_server.primary.id, null)
  db_server_name = try(azurerm_mysql_flexible_server.primary.name, null)
  db_fqdn        = try(azurerm_mysql_flexible_server.primary.fqdn, null)
}

# ============================================================
# Korea / Japan Azure MySQL
# On-Prem MySQL : Source of Truth
# Korea / Japan Azure MySQL : Data-in Replica + Failover Target
# Replication : On-Prem -> Korea and On-Prem -> Japan
# ============================================================
resource "azurerm_mysql_flexible_server" "primary" {
  #count = var.create_database ? 1 : 0

  name                = "${var.prefix}-mysql-${var.region_code}${var.global_name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  version                = "8.0.21"
  administrator_login    = var.db_user
  administrator_password = var.db_password
  sku_name               = local.db_sku

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = azurerm_subnet.db_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.db.id

  storage {
    size_gb           = 32
    auto_grow_enabled = true
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.db_spoke]
}

resource "azurerm_mysql_flexible_database" "app" {
  #count = var.create_database ? 1 : 0

  name                = var.db_name
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Azure DB는 TLS를 강제한다. Korea WAS는 SSL로 연결한다.
resource "azurerm_mysql_flexible_server_configuration" "secure_transport" {
  #count = var.create_database ? 1 : 0

  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_enabled" {
  #count = var.create_database ? 1 : 0

  name                = "audit_log_enabled"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_events" {
  #count = var.create_database ? 1 : 0

  name                = "audit_log_events"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "CONNECTION,DML,DDL,DCL"
}

resource "azurerm_mysql_flexible_server_configuration" "slow_query_log" {
  #count = var.create_database ? 1 : 0

  name                = "slow_query_log"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "long_query_time" {
  #count = var.create_database ? 1 : 0

  name                = "long_query_time"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "2"
}

# 02_hybrid Data-out Replication 준비: binlog 보존 기간 7일
resource "azurerm_mysql_flexible_server_configuration" "binlog_expire" {
  #count = var.create_database ? 1 : 0

  name                = "binlog_expire_logs_seconds"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "604800"
}

# Azure DB는 Data-in Replication 초기 seed 및 장애 시 쓰기 수용이 필요하므로 read_only를 OFF로 유지한다.
# 정상 운영 중 애플리케이션 쓰기는 HAProxy가 On-Prem Active로 전달한다.
resource "azurerm_mysql_flexible_server_configuration" "read_only_mode" {
  name                = "read_only"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.primary.name
  value               = "OFF"
}

# ============================================================
# Private Endpoint + Private DNS (Korea only)
# ============================================================
resource "azurerm_private_dns_zone" "db" {
  #count = var.create_database ? 1 : 0

  name                = "${var.region_code}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_spoke" {
  name                  = "${var.prefix}-mysql-dns-spoke-${var.region_code}"
  # resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_id = azurerm_private_dns_zone.db.id
  virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_hub" {
  name                  = "${var.prefix}-mysql-dns-hub-${var.region_code}"
  # resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_id = azurerm_private_dns_zone.db.id
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  registration_enabled  = false

  tags = var.tags
}
