# Passerelle NAT : sortie Internet de la VM (Docker, ACR) sans IP publique sur la VM.
# Le Load Balancer gère l'entrée, la NAT gère la sortie (disable_outbound_snat sur la règle du LB).

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  name                    = "natgw-${var.name_suffix}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Seul snet-app sort par la NAT (snet-data n'a que des private endpoints)
resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
