locals {
  app_vm_size = "Standard_B2ts_v2"
  admin_user  = "3team"
  app_db_host = var.create_database ? local.db_fqdn : var.external_db_host
}

# ============================================================
# Management VM
# ============================================================
resource "azurerm_network_interface" "mgmt" {
  name                = "${var.prefix}-mgmt-nic-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  ip_configuration {
    name                          = "mgmt-ip"
    subnet_id                     = azurerm_subnet.mgmt_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.mgmt_private_ip
    public_ip_address_id          = azurerm_public_ip.mgmt_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "mgmt" {
  name                = "${var.prefix}-mgmt-vm-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = local.app_vm_size
  admin_username      = local.admin_user
  tags                = var.tags

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.mgmt.id]
  custom_data                     = base64encode(file("${path.module}/mgmt.sh"))

  admin_ssh_key {
    username   = local.admin_user
    #public_key = var.admin_ssh_public_key
    public_key = file("${path.module}/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  # Rocky Linux Marketplace image는 Plan 정보가 필요하다.
  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }
}

# ============================================================
# WEB VMSS - Stateless
# ============================================================
resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "${var.prefix}-web-vmss-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = local.app_vm_size
  instances           = 1
  admin_username      = local.admin_user
  upgrade_mode        = "Manual"
  tags                = var.tags

  custom_data = base64encode(templatefile("${path.module}/web.sh", {
    region_code = var.region_code
    region_role = var.region_role
    was_lb_ip = var.internal_lb_private_ip
  }))

  admin_ssh_key {
    username   = local.admin_user
    # public_key = var.admin_ssh_public_key
    public_key = file("${path.module}/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  network_interface {
    name    = "web-nic"
    primary = true

    ip_configuration {
      name      = "web-ip"
      primary   = true
      subnet_id = azurerm_subnet.web_subnet.id

      application_gateway_backend_address_pool_ids = [
        one([
          for pool in azurerm_application_gateway.appgw.backend_address_pool :
          pool.id if pool.name == "web-backend"
        ])
      ]
    }
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

# ============================================================
# WAS VMSS - Stateless / 모든 회원 데이터는 DB 저장
# Korea : Azure MySQL Private Endpoint
# Japan : 02_hybrid에서 On-Prem MySQL(192.168.10.203) 사용
# ============================================================
resource "azurerm_linux_virtual_machine_scale_set" "was" {
  name                = "${var.prefix}-was-vmss-${var.region_code}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = local.app_vm_size
  instances           = 1
  admin_username      = local.admin_user
  upgrade_mode        = "Manual"
  tags                = var.tags

  custom_data = base64encode(templatefile("${path.module}/was.sh", {
    region_code = var.region_code
    region_role = var.region_role

    db_host     = azurerm_container_group.db_proxy.ip_address
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
  }))

  admin_ssh_key {
    username   = local.admin_user
    public_key = file("${path.module}/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  network_interface {
    name    = "was-nic"
    primary = true

    ip_configuration {
      name      = "was-ip"
      primary   = true
      subnet_id = azurerm_subnet.was_subnet.id
      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.was_backend_pool.id
      ]
    }
  }

  lifecycle {
    ignore_changes = [instances]
  }

  depends_on = [azurerm_container_group.db_proxy]

}
