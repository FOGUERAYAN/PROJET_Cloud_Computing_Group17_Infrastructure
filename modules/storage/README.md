# Module `storage`

**Responsable :** Hafsatou

Compte de stockage de l'application CAP90 (région `francecentral`, groupe `rg-cap90-prod-frc`).
L'application lit `AZURE_STORAGE_ACCOUNT_NAME` et s'authentifie avec `DefaultAzureCredential` : **aucune clé** n'est utilisée ni exposée.

## Ressources créées

| Ressource | Détail |
|---|---|
| `azurerm_storage_account.main` | `st<name_prefix>frc` (par défaut `stcap90prodfrc`, 24 caractères max, minuscules). StorageV2 Standard, **ZRS**, TLS 1.2 minimum, HTTPS obligatoire, accès anonyme aux blobs désactivé, suivi du dernier accès activé. |
| Règles réseau (dans le compte) | `default_action = Deny`, `virtual_network_subnet_ids = allowed_subnet_ids`, `ip_rules = allowed_ips`, `bypass = AzureServices`. |
| `azurerm_storage_container.main` | `coffre`, `annonces-photos`, `medias-lille` (privés). |
| `azurerm_storage_table.main` | `profils`, `etapes`, `annonces`, `heures`. |
| `azurerm_storage_management_policy.main` | `coffre` : Hot vers Cool après 90 jours sans accès. `annonces-photos` : suppression à J+30 après création. |
| `azurerm_private_endpoint.blob` | Si `create_private_endpoint` : endpoint `blob` dans `snet-data` (10.0.2.0/24). |
| `azurerm_private_dns_zone.blob` + lien VNet | Zone `privatelink.blob.core.windows.net`, liée au VNet déduit de `subnet_data_id`. |
| `azurerm_role_assignment.data` | Pour chaque `principal_id` : Storage Blob Data Contributor, Storage Table Data Contributor, Storage Blob Delegator, portée sur le compte. Liste vide : aucune attribution (le module sécurité s'en charge). |

Toutes les ressources qui le supportent reçoivent `tags` (owner, project, environment).

## Variables

| Nom | Type | Défaut | Description |
|---|---|---|---|
| `resource_group_name` | string | — | Groupe de ressources (`rg-cap90-prod-frc`). |
| `location` | string | — | Région (`francecentral`). |
| `tags` | map(string) | — | owner, project, environment. |
| `subnet_data_id` | string | — | ID de `snet-data`, reçoit le private endpoint. L'ID du VNet en est déduit. |
| `allowed_subnet_ids` | list(string) | `[]` | Sous-réseaux autorisés (`snet-app`, `snet-data`). |
| `allowed_ips` | list(string) | `[]` | IP/CIDR autorisées (IP du déployeur). |
| `principal_ids` | list(string) | `[]` | Object IDs qui reçoivent les rôles data-plane. |
| `name_prefix` | string | `"cap90prod"` | Préfixe du nom : `st<name_prefix>frc`. Minuscules et chiffres, 19 caractères max. |
| `create_private_endpoint` | bool | `true` | Crée le private endpoint blob et la zone DNS privée. |
| `public_network_access_enabled` | bool | `true` | Point de terminaison public (filtré par les règles réseau). |
| `shared_access_key_enabled` | bool | `true` | Authentification par clé partagée (voir la note ci-dessous). |

## Sorties

| Nom | Description |
|---|---|
| `storage_account_name` | Valeur de `AZURE_STORAGE_ACCOUNT_NAME`. |
| `storage_account_id` | ID ARM du compte. |
| `primary_blob_endpoint` | Point de terminaison Blob principal. |
| `container_names` | Noms des conteneurs. |
| `table_names` | Noms des tables. |

Aucune clé d'accès ni chaîne de connexion n'est exposée en sortie.

## Note sur `shared_access_key_enabled`

La valeur par défaut est `true` pour que Terraform puisse créer les conteneurs et les tables sans configuration supplémentaire.

`false` est plus strict (plus aucune authentification par clé possible), mais exige :

- l'authentification Entra ID (AAD) côté data-plane pour Terraform : `storage_use_azuread = true` dans le bloc `provider "azurerm"` ;
- les rôles **Storage Blob Data Contributor** et **Storage Table Data Contributor** pour l'identité qui lance `terraform apply` sur ce compte ;
- que l'IP du déployeur figure dans `allowed_ips` (règles réseau en `Deny`).

À noter : les conteneurs et les tables sont déclarés avec `storage_account_id`, donc créés via l'API ARM (plan de gestion). Le passage à `false` concerne surtout les lectures data-plane que le provider fait sur le compte.

L'application, elle, n'utilise jamais la clé : elle passe par `DefaultAzureCredential` et les rôles RBAC.

## Création des conteneurs et tables

L'application garde une création if-not-exists en secours, mais Terraform est la source officielle.

## Exemple d'appel

Voir [`envs/prod/README.md`](../../envs/prod/README.md).
