# was 에 대한 lb
resource "azurerm_lb" "internal_lb" {
    name = "lb-was-internal-${var.region_code}"
    location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Standard"

  frontend_ip_configuration {
    name = "internal-lb-frontend-privatei-ip"
    subnet_id = azurerm_subnet.was_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.internal_lb_private_ip
  }
}

resource "azurerm_lb_backend_address_pool" "was_backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name = "pool-was-backend"
}

resource "azurerm_lb_probe" "was_hp" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name = "hp-was-80"
  protocol = "Http"
  port = 80
  request_path = "/health.php"
  interval_in_seconds = 5
  number_of_probes = 2

}

resource "azurerm_lb_rule" "lib_rule_80" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name = "rule-web-to-was-80"
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  frontend_ip_configuration_name = "internal-lb-frontend-privatei-ip" # 동일
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.was_backend_pool.id]
  probe_id = azurerm_lb_probe.was_hp.id
}