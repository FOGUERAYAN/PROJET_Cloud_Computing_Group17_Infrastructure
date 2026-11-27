# Réseau : VNet, 2 sous-réseaux et leurs NSG.
# Le Load Balancer est dans lb.tf, la passerelle NAT dans nat.tf.

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Sous-réseau app : la VM qui fait tourner le conteneur Flask/Gunicorn
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_app_prefix]

  # Requis par les règles réseau du stockage (Hafsatou) et du Key Vault (Maroua)
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Sous-réseau data : points de terminaison privés du stockage et du Key Vault
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_data_prefix]

  service_endpoints = ["Microsoft.Storage"]

  # Active le filtrage NSG sur le trafic vers les private endpoints
  private_endpoint_network_policies = "Enabled"
}

# ---------- NSG snet-app : seulement le port de l'app depuis Internet ----------
# Pas de port 22 (SSH) : tout le reste est bloqué par la règle par défaut DenyAllInBound.
# Les sondes du Load Balancer passent grâce à la règle par défaut AllowAzureLoadBalancerInBound.
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-App-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = "Internet"
    destination_address_prefix = var.subnet_app_prefix
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ---------- NSG snet-data : 443 depuis snet-app uniquement ----------
# La règle Deny-VNet-Inbound (4000) passe avant la règle par défaut AllowVnetInBound (65000),
# sinon tout le VNet pourrait joindre snet-data.
resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTPS-From-App"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_app_prefix
    destination_address_prefix = var.subnet_data_prefix
  }

  security_rule {
    name                       = "Deny-VNet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}
