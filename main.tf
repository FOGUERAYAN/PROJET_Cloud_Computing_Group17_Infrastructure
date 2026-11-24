# Chef d'orchestre : crée le groupe de ressources et appelle chaque module.
# Convention de nommage : <type>-<projet>-<env>-<région>  (ex. rg-cap90-prod-frc)

locals {
  name_suffix = "${var.project}-${var.environment}-${var.location_short}"

  # Tags obligatoires (owner, project, environment), appliqués à TOUTES les ressources.
  # Liste à valider avec Maroua (elle écrit la Policy qui les impose).
  tags = {
    owner       = var.owner
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# --- P1 : réseau ---
module "network" {
  source = "./modules/network"

  name_suffix         = local.name_suffix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  vnet_address_space = var.vnet_address_space
  subnet_app_prefix  = var.subnet_app_prefix
  subnet_data_prefix = var.subnet_data_prefix
}

# --- P1 : calcul (VM + Function) --- à brancher en phase 2
# module "compute" {
#   source = "./modules/compute"
#   ...
#   subnet_app_id         = module.network.subnet_app_id
#   app_identity_id       = module.security.app_identity_id   # identité créée par Maroua
# }

# --- P3 (Hafsatou) : stockage ---
# module "storage" { source = "./modules/storage" ... }

# --- P2 (Maroua) : sécurité et supervision ---
# module "security"   { source = "./modules/security" ... }
# module "monitoring" { source = "./modules/monitoring" ... }
