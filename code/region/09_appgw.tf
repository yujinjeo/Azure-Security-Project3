# ============================================================
# Application Gateway WAF Policy
# - 처음에는 Detection으로 검증하고, 이후 Prevention으로 전환 가능
# - OWASP CRS 3.2 사용
# ============================================================
resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.prefix}-waf-policy-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  policy_settings {
    enabled            = true
    mode               = var.waf_mode
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix}-appgw-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf.id
  tags                = var.tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "web-backend"
  }


  backend_http_settings {
    name                  = "web-http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "web-probe"
  }

  probe {
    name                = "web-probe"
    protocol            = "Http"
    path                = "/health.php"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3

    match {
      status_code = ["200-399"]
    }
  }


  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }


  request_routing_rule {
    name               = "routing-rule"
    priority           = 100
    # rule_type          = "PathBasedRouting"
    rule_type = "Basic"
    http_listener_name = "http-listener"
    # url_path_map_name  = "path-map"
    backend_address_pool_name = "web-backend" # 동일
    backend_http_settings_name = "web-http-setting" # 동일
  }
}
