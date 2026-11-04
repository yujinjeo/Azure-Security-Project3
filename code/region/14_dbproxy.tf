resource "azurerm_storage_share" "proxy_share" {
    name = "haproxy-config"
    storage_account_id = azurerm_storage_account.app.id
    quota = 1
}

resource "local_file" "haproxy_rendered" {
  filename = "${path.module}/rendered_haproxy_${var.region_code}.cfg"
  content  = templatefile("${path.module}/haproxy.cfg", {
    db_address          = azurerm_mysql_flexible_server.primary.fqdn
    force_standby      = var.db_proxy_force_standby
  })
}

resource "azurerm_storage_share_file" "haproxy_cfg" {
    name = "haproxy.cfg"
    storage_share_url = azurerm_storage_share.proxy_share.url
    source = local_file.haproxy_rendered.filename

    depends_on = [azurerm_mysql_flexible_server.primary]
    
}

resource "azurerm_container_group" "db_proxy" {
    name ="db_proxy_${var.region_code}"
    location = var.location
    resource_group_name = azurerm_resource_group.rg.name
    os_type = "Linux"

    ip_address_type = "Private"
    subnet_ids =[azurerm_subnet.proxy_subnet.id]

    exposed_port {
        port =3306
        protocol = "TCP"
    }

    container {
        name = "haproxy"
        image = "haproxy:latest"
        cpu = "1.0"
        memory = "1.5"

        ports {
            port = 3306
            protocol = "TCP"
        }

        volume {
            name = "haproxy-volume"
            mount_path = "/usr/local/etc/haproxy"
            read_only = true
            share_name = azurerm_storage_share.proxy_share.name
            storage_account_name = azurerm_storage_account.app.name
            storage_account_key = azurerm_storage_account.app.primary_access_key
        }
    }

    depends_on = [azurerm_storage_share_file.haproxy_cfg]
}