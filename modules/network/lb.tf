# IP publique + Load Balancer Standard devant la VM de l'app.
# Le trafic Internet arrive sur le port 80, le LB l'envoie au port 8000 de la VM.

resource "azurerm_public_ip" "lb" {
  name                = "pip-lb-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.name_suffix
  tags                = var.tags
}

resource "azurerm_lb" "main" {
  name                = "lb-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "fe-public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Pool backend : la VM du module compute s'y ajoutera
resource "azurerm_lb_backend_address_pool" "app" {
  name            = "bepool-app"
  loadbalancer_id = azurerm_lb.main.id
}

# Sonde de santé : le LB n'envoie du trafic qu'aux VM qui répondent sur /health
resource "azurerm_lb_probe" "health" {
  name                = "probe-health"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  port                = var.app_port
  request_path        = "/health"
  interval_in_seconds = 15
}

# Règle : port 80 public vers port 8000 de la VM
# disable_outbound_snat : la sortie Internet de la VM passera par la passerelle NAT
resource "azurerm_lb_rule" "http" {
  name                           = "rule-http-80"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = var.app_port
  frontend_ip_configuration_name = "fe-public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app.id]
  probe_id                       = azurerm_lb_probe.health.id
  disable_outbound_snat          = true
}
