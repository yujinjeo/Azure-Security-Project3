# ============================================================
# Traffic Manager : Korea Priority 1 / Japan Priority 2
# DNS prefix는 Azure 전체에서 고유해야 하므로 lab_id를 붙인다.
# ============================================================
resource "azurerm_traffic_manager_profile" "tm" {
  name                   = "${local.prefix}-tm${var.lab_id}"
  resource_group_name    = module.korea.rg_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${local.prefix}-tm${var.lab_id}"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/health.php"
    interval_in_seconds          = 10
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 1
  }

  tags = var.common_tags
}

resource "azurerm_traffic_manager_external_endpoint" "korea" {
  name       = "korea-primary"
  profile_id = azurerm_traffic_manager_profile.tm.id
  target     = module.korea.appgw_public_ip
  priority   = 1
}

resource "azurerm_traffic_manager_external_endpoint" "japan" {
  name       = "japan-standby"
  profile_id = azurerm_traffic_manager_profile.tm.id
  target     = module.japan.appgw_public_ip
  priority   = 2
}

# Optional custom domain -> Traffic Manager
resource "azurerm_dns_a_record" "root" {
  count = var.enable_custom_dns ? 1 : 0

  name                = "@"
  zone_name           = var.dns_name
  resource_group_name = module.korea.rg_name
  ttl                 = 30
  target_resource_id  = azurerm_traffic_manager_profile.tm.id
}

resource "azurerm_dns_a_record" "www" {
  count = var.enable_custom_dns ? 1 : 0

  name                = "www"
  zone_name           = var.dns_name
  resource_group_name = module.korea.rg_name
  ttl                 = 30
  target_resource_id  = azurerm_traffic_manager_profile.tm.id
}
