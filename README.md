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

Les fichiers racine (`backend.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`) et `envs/prod.tfvars` sont ajoutés par Godwin.

## Contrat d'interface

Noms partagés entre l'application et l'infrastructure. **On ne les modifie pas sans prévenir toute l'équipe** (PR + message sur le groupe).

| Élément | Valeur | Fourni par |
|---|---|---|
| Région Azure | France Central *(à confirmer)* | Godwin |
| Port de l'application | `8000` | Hafsatou |
| Sonde de santé | `GET /health` → HTTP 200 | Hafsatou |
| Image Docker | `Dockerfile` à la racine du dépôt applicatif, utilisateur non root, port 8000. Nom dans l'ACR *à définir* | Hafsatou / Maroua |
| VNet | `10.0.0.0/16` | Godwin |
| Sous-réseau app | `10.0.1.0/24` | Godwin |
| Sous-réseau data | `10.0.2.0/24` | Godwin |
| Conteneurs Blob | `medias-lille` (photos des lieux), `coffre` (créé plus tard, V1), `annonces-photos` *(prévu, pas encore utilisé)* | Hafsatou |
| Tables | `profils`, `etapes`, `heures`, `annonces` | Hafsatou |
| Variables d'environnement (lues par l'app) | `STORAGE_MODE=azure`, `AZURE_STORAGE_ACCOUNT_NAME`, `SECRET_KEY` (obligatoire, sans valeur par défaut) | Hafsatou / Maroua |
| Variables d'environnement (prévues, pas encore lues) | `KEY_VAULT_URL`, `APPLICATIONINSIGHTS_CONNECTION_STRING` | Hafsatou / Maroua |
| Tags obligatoires | `owner`, `project`, `environment` | Maroua |
| Nom de l'ACR, du Key Vault | *à définir* | Maroua |
| Compte de stockage du remote state | *à définir* | Godwin |

Notes sur l'alignement avec l'application (PR #1 du dépôt applicatif) :

- `STORAGE_MODE` vaut `memoire` (défaut), `azurite` ou `azure`. En production, le mettre à `azure` : l'app utilise alors `DefaultAzureCredential` (Managed Identity) avec le compte `AZURE_STORAGE_ACCOUNT_NAME`.
- `SECRET_KEY` doit être fournie à l'application au démarrage (Key Vault ou variable injectée par Terraform). Sans elle, l'application refuse de démarrer.
- L'app crée elle-même les tables et le conteneur `medias-lille` au démarrage : la Managed Identity a besoin de `Storage Table Data Contributor` et `Storage Blob Data Contributor`.
- Le port 8000 est fixé dans le Dockerfile : l'app ne lit pas de variable `PORT`.

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
