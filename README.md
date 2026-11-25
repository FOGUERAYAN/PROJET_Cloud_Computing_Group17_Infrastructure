# Cap90 – Infrastructure Azure (Terraform)

Infrastructure as Code du projet Cloud Computing (JUNIA ISEN, équipe 17). Elle déploie sur Microsoft Azure l'application **Cap90**, qui accompagne les nouveaux arrivants en France pendant leurs trois premiers mois.

- Dépôt de l'application : [PROJET-Cloud_Computing_Group17](https://github.com/FOGUERAYAN/PROJET-Cloud_Computing_Group17)
- Rapport : [`docs/`](docs/)
- Règles de travail : [CONTRIBUTING.md](CONTRIBUTING.md)

## Équipe

| Membre | Périmètre | Modules |
|---|---|---|
| Godwin | Réseau, calcul, remote state | `network`, `compute` |
| Maroua | Sécurité, gouvernance, supervision, coûts | `security`, `monitoring` |
| Hafsatou | Application, stockage | `storage` |
| Rayan | Git, CI/CD, rapport | `.github/`, `docs/` |

## Structure du dépôt

```
.
├── .github/
│   ├── workflows/ci.yml          # CI : fmt, validate, tflint, gitleaks
│   └── pull_request_template.md
├── modules/
│   ├── network/                  # VNet, sous-réseaux, NSG, Load Balancer, NAT
│   ├── compute/                  # VM (ou VMSS), Azure Function
│   ├── storage/                  # Blob, Table, cycle de vie
│   ├── security/                 # Managed Identity, Key Vault, RBAC, Policy
│   └── monitoring/               # Log Analytics, App Insights, alertes, dashboard
├── envs/                         # prod.tfvars (configuration prod, sans secret)
├── docs/                         # rapport et schémas draw.io
├── .tflint.hcl
└── CONTRIBUTING.md
```

Les fichiers racine (`backend.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`) et `envs/prod.tfvars` sont ceux de Godwin. Le module racine est à la **racine du dépôt** : les appels de modules se font dans `main.tf`.

## Contrat d'interface

Noms partagés entre l'application et l'infrastructure. **On ne les modifie pas sans prévenir toute l'équipe** (PR + message sur le groupe).

### Valeurs

| Élément | Valeur | Fourni par |
|---|---|---|
| Région Azure | `francecentral` | Godwin |
| Port de l'application | `8000` (fixé dans le Dockerfile, pas de variable `PORT`) | Hafsatou |
| Sonde de santé | `GET /health` → HTTP 200 | Hafsatou |
| Image Docker | `<acr>.azurecr.io/cap90:<sha du commit>` (un tag par commit, pas de `latest`). Utilisateur non root, port 8000. Nom de l'ACR *à définir* | Hafsatou / Maroua |
| VNet | `10.0.0.0/16` | Godwin |
| Sous-réseau app | `snet-app` `10.0.1.0/24` | Godwin |
| Sous-réseau data | `snet-data` `10.0.2.0/24` | Godwin |
| Service endpoint | `Microsoft.Storage` sur `snet-app` et `snet-data` | Godwin |
| Compte de stockage | `stcap90prodfrc` (`st` + `name_prefix` + `frc`, avec `name_prefix = "cap90prod"`) | Hafsatou |
| Conteneurs Blob | `coffre`, `annonces-photos`, `medias-lille` | Hafsatou |
| Tables | `profils`, `etapes`, `annonces`, `heures` | Hafsatou |
| Tags obligatoires | `owner`, `project`, `environment` | Maroua |
| Nom de l'ACR, du Key Vault | *à définir* | Maroua |
| Remote state | groupe `rg-cap90-tfstate`, compte `sttfstatecap90gd`, conteneur `tfstate`, clé `prod.terraform.tfstate` (voir [bootstrap](docs/bootstrap-remote-state.md)) | Godwin |

### Variables d'environnement du conteneur

| Variable | Valeur | Statut | Fournie par |
|---|---|---|---|
| `STORAGE_MODE` | `azure` | lue par l'app | Godwin (compute) |
| `AZURE_STORAGE_ACCOUNT_NAME` | `module.storage.storage_account_name` (remplace `STORAGE_ACCOUNT_NAME`) | lue par l'app | Hafsatou |
| `SECRET_KEY` | injectée depuis le Key Vault, obligatoire (l'app refuse de démarrer sans elle) | lue par l'app | Maroua |
| `KEY_VAULT_URL` | URL du Key Vault | prévue, pas encore lue | Maroua |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | chaîne de connexion Application Insights | prévue, pas encore lue | Maroua |
| `AZURE_CLIENT_ID` | client ID de l'identité | seulement si l'identité est user-assigned (lu par `DefaultAzureCredential`) | Maroua |
| `PHOTOS_CONTACT` | contact de l'équipe | facultative (script de photos, hors VM) | Hafsatou |

### Sorties attendues des modules

| Sortie | Fournie par |
|---|---|
| `module.network.snet_app_id`, `module.network.snet_data_id` | Godwin |
| `module.security.app_identity_principal_id` | Maroua |
| `storage_account_name`, `storage_account_id`, `primary_blob_endpoint`, `container_names`, `table_names` | Hafsatou |

Variable racine `deployer_ips` (`list(string)`) : IP du déployeur autorisées sur le compte de stockage, renseignée **hors Git** (`TF_VAR_deployer_ips='["x.x.x.x"]'`).

### Notes

- `STORAGE_MODE` vaut `memoire` (défaut), `azurite` ou `azure`. En production : `azure`, avec `DefaultAzureCredential` (identité managée).
- Rôles de l'identité sur le compte de stockage : `Storage Blob Data Contributor`, `Storage Table Data Contributor` et `Storage Blob Delegator` (liens de partage de 24 h en User Delegation SAS).
- Le compte de stockage refuse tout accès par défaut (`default_action = Deny`) : il faut le service endpoint sur les sous-réseaux et `deployer_ips` pour le déployeur.

## CI

Le workflow [`ci.yml`](.github/workflows/ci.yml) s'exécute sur chaque Pull Request vers `main` et sur chaque push sur `main` :

| Job | Vérifications |
|---|---|
| `terraform` | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, `tflint` |
| `gitleaks` | recherche de secrets dans tout l'historique Git |

`init -backend=false` permet de valider la configuration sans se connecter à Azure.

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.9
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), connecté avec `az login` à l'abonnement Azure for Students de l'équipe
- Un rôle suffisant sur l'abonnement (Contributor + User Access Administrator pour les attributions RBAC)

## Initialisation du remote state (action manuelle)

> Section complétée par Godwin : commandes `az` de création du groupe de ressources, du compte de stockage et du conteneur `tfstate`. C'est la seule action manuelle autorisée par le sujet. Le verrouillage est assuré par le bail (lease) natif des blobs Azure.

## Déploiement

> À compléter quand les modules sont prêts.

```bash
terraform init
terraform plan  -var-file=envs/prod.tfvars
terraform apply -var-file=envs/prod.tfvars
```

## Destruction

```bash
terraform destroy -var-file=envs/prod.tfvars
```

Le compte de stockage du remote state n'est pas géré par Terraform : il se supprime à part (voir la section d'initialisation).
