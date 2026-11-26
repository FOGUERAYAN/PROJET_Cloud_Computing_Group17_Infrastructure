output "resource_group_name" {
  description = "Nom du groupe de ressources principal"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Nom du VNet"
  value       = module.network.vnet_name
}

output "subnet_app_id" {
  description = "ID du sous-réseau app (pour Maroua et Hafsatou)"
  value       = module.network.subnet_app_id
}

output "subnet_data_id" {
  description = "ID du sous-réseau data (private endpoints du stockage / Key Vault)"
  value       = module.network.subnet_data_id
}

# À ajouter en phase 2 : app_url (IP publique du Load Balancer), noms de la VM et de la Function.
output "app_url" {
  description = "URL publique de l'application (via le Load Balancer)"
  value       = "http://${module.network.app_fqdn}"
}

# --- Stockage (P3) : aucune clé exposée ---
output "storage_account_name" {
  description = "Nom du compte de stockage (AZURE_STORAGE_ACCOUNT_NAME de l'application)"
  value       = module.storage.storage_account_name
}

output "storage_account_id" {
  description = "ID ARM du compte de stockage (portée RBAC pour le module sécurité)"
  value       = module.storage.storage_account_id
}

output "primary_blob_endpoint" {
  description = "Point de terminaison Blob principal"
  value       = module.storage.primary_blob_endpoint
}

