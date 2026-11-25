# Aucune clé d'accès ni chaîne de connexion n'est exposée.

output "storage_account_name" {
  description = "Nom du compte (valeur de AZURE_STORAGE_ACCOUNT_NAME pour l'application)"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID ARM du compte de stockage"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Point de terminaison Blob principal"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_names" {
  description = "Noms des conteneurs Blob créés"
  value       = [for c in azurerm_storage_container.main : c.name]
}

output "table_names" {
  description = "Noms des tables créées"
  value       = [for t in azurerm_storage_table.main : t.name]
}
