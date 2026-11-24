# Initialisation manuelle du remote state

Seule opération faite hors Terraform (autorisée par le sujet). Faite une seule fois, le 24/11/2026, par Godwin.

## Ressources créées

| Ressource | Nom | Réglages |
|---|---|---|
| Groupe de ressources | `rg-cap90-tfstate` | `francecentral` |
| Compte de stockage | `sttfstatecap90gd` | Standard_LRS, StorageV2, TLS 1.2 minimum, accès public aux blobs désactivé, HTTPS uniquement |
| Conteneur Blob | `tfstate` | privé |

## Commandes (Azure CLI)

```
az login
az account show
az storage account check-name --name sttfstatecap90gd
az group create --name rg-cap90-tfstate --location francecentral
az storage account create --name sttfstatecap90gd --resource-group rg-cap90-tfstate --location francecentral --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --name tfstate --account-name sttfstatecap90gd --auth-mode key
```

## Choix et justification

- **Pourquoi à la main :** Terraform a besoin que le stockage de son état existe avant son premier `terraform init`. Le sujet autorise cette seule opération manuelle, à condition de la documenter.
- **Réplication LRS :** le fichier d'état est petit et l'infrastructure peut être recréée à partir du code ; une réplication plus chère n'apporte rien ici.
- **Verrouillage (locking) :** assuré nativement par Azure. Terraform pose un bail (lease) sur le blob pendant chaque `plan`/`apply`, ce qui empêche deux exécutions simultanées.
- **Hors de Git :** le fichier d'état contient des identifiants internes et potentiellement des valeurs sensibles ; il n'est jamais versionné.
- **Non géré par Terraform :** `terraform destroy` ne supprime pas ce groupe de ressources, ce qui protège l'historique de l'état.

## Pour supprimer (fin du projet uniquement)

```
az group delete --name rg-cap90-tfstate
```
