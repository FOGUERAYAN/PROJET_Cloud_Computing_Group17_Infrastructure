# Environnement prod : exemples d'appel

Les valeurs de l'environnement restent dans [`envs/prod.tfvars`](../prod.tfvars) (aucun secret).
Les appels de modules se font dans le `main.tf` racine (câblage par Godwin).

## Module `storage`

À coller dans `main.tf`, à la place du bloc commenté `# module "storage"` :

```hcl
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name # rg-cap90-prod-frc
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  subnet_data_id = module.network.subnet_data_id # snet-data 10.0.2.0/24 (private endpoint)

  allowed_subnet_ids = [
    module.network.subnet_app_id,  # snet-app 10.0.1.0/24
    module.network.subnet_data_id, # snet-data 10.0.2.0/24
  ]

  # IP publique du déployeur : à passer en variable, jamais en dur dans un fichier versionné.
  allowed_ips = var.deployer_ips

  # Vide : les rôles data-plane sont attribués par le module sécurité.
  principal_ids = []

  # Valeurs par défaut, rappelées pour lisibilité :
  # name_prefix                   = "cap90prod"   # -> stcap90prodfrc
  # create_private_endpoint       = true
  # public_network_access_enabled = true
  # shared_access_key_enabled     = true
}
```

Prérequis côté racine :

- les sous-réseaux `snet-app` et `snet-data` doivent avoir le service endpoint `Microsoft.Storage` pour être acceptés dans les règles réseau du compte ;
- une variable `deployer_ips` (`list(string)`), renseignée hors Git (par exemple `TF_VAR_deployer_ips='["x.x.x.x"]'`).

Sortie utile pour l'application : `module.storage.storage_account_name` → `AZURE_STORAGE_ACCOUNT_NAME`.
