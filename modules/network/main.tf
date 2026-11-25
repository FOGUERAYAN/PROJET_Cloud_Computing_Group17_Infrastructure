# Phase 1 : VNet + 2 sous-réseaux.
# Phase 2 : NSG, IP publique, Load Balancer, passerelle NAT (à ajouter ici).

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

  # Requis par les règles réseau du compte de stockage (module storage)
  service_endpoints = ["Microsoft.Storage"]
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