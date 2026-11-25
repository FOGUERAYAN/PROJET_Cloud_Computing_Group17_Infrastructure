# Module storage : compte de stockage, conteneurs, tables, cycle de vie,
# private endpoint blob et attributions RBAC data-plane.
# L'application lit AZURE_STORAGE_ACCOUNT_NAME et s'authentifie avec DefaultAzureCredential (sans clé).

locals {
  storage_account_name = "st${var.name_prefix}frc"

  container_names = ["coffre", "annonces-photos", "medias-lille"]
  table_names     = ["profils", "etapes", "annonces", "heures"]

  # ID du VNet déduit de subnet_data_id (.../virtualNetworks/<vnet>/subnets/<snet>)
  vnet_id = regex("^(.*)/subnets/[^/]+$", var.subnet_data_id)[0]

  data_roles = [
    "Storage Blob Data Contributor",
    "Storage Table Data Contributor",
    "Storage Blob Delegator",
  ]

  # Clés par index et rôle : connues au plan même si les principal_ids viennent d'un autre module.
  role_assignments = {
    for pair in setproduct(range(length(var.principal_ids)), local.data_roles) :
    "${pair[0]}-${pair[1]}" => {
      principal_id = var.principal_ids[pair[0]]
      role         = pair[1]
    }
  }
}

resource "azurerm_storage_account" "main" {
  name                = local.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  blob_properties {
    last_access_time_enabled = true
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ips
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(local.storage_account_name) <= 24
      error_message = "Le nom du compte de stockage dépasse 24 caractères."
    }
  }
}

resource "azurerm_storage_container" "main" {
  for_each = toset(local.container_names)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_table" "main" {
  for_each = toset(local.table_names)

  name               = each.value
  storage_account_id = azurerm_storage_account.main.id
}

resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "coffre-cool-90j-sans-acces"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["coffre/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_last_access_time_greater_than = 90
      }
    }
  }

  rule {
    name    = "annonces-photos-suppression-30j"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["annonces-photos/"]
    }

    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }

  depends_on = [azurerm_storage_container.main]
}

# --- Private endpoint blob dans snet-data ---

resource "azurerm_private_dns_zone" "blob" {
  count = var.create_private_endpoint ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.create_private_endpoint ? 1 : 0

  name                  = "link-blob-${local.storage_account_name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  count = var.create_private_endpoint ? 1 : 0

  name                = "pe-${local.storage_account_name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_data_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}

# --- RBAC data-plane (vide si principal_ids = []) ---

resource "azurerm_role_assignment" "data" {
  for_each = local.role_assignments

  scope                = azurerm_storage_account.main.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
