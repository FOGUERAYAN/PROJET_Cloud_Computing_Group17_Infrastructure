# Authentification GitHub Actions → Azure (OIDC)

Actions faites à la main, hors Terraform, le 25/11/2026 par Rayan. Elles permettent à la CI de publier l'image Docker dans l'ACR sans mot de passe (workflow `publish.yml` du dépôt application).

## Tentative 1 : application Entra ID (refusée)

```
az ad app create --display-name "cap90-github-oidc"
```

Résultat : `Insufficient privileges to complete the operation`. Sur Azure for Students, le compte est propriétaire (Owner) de l'abonnement mais n'a aucun droit sur l'annuaire Entra ID du tenant de l'école : on ne peut pas créer d'inscription d'application, de service principal ni d'identifiant fédéré dessus. Rien n'a été créé.

## Solution retenue : identité managée user-assigned

Une identité managée est une ressource Azure ordinaire : elle ne demande que les droits sur l'abonnement, et elle accepte aussi les identifiants fédérés GitHub.

| Ressource | Nom | Remarque |
|---|---|---|
| Groupe de ressources | `rg-cap90-ci` | `francecentral`, séparé de `rg-cap90-prod-frc` pour ne pas être supprimé par un `terraform destroy` |
| Identité managée | `id-cap90-github` | tags `owner`, `project`, `environment` |
| Identifiant fédéré | `github-main` | sujet `repo:FOGUERAYAN/PROJET-Cloud_Computing_Group17:ref:refs/heads/main`, audience `api://AzureADTokenExchange` |

```
az group create -n rg-cap90-ci -l francecentral \
  --tags owner=team-cap90 project=cap90 environment=prod

az identity create -g rg-cap90-ci -n id-cap90-github -l francecentral \
  --tags owner=team-cap90 project=cap90 environment=prod

az identity federated-credential create -g rg-cap90-ci --identity-name id-cap90-github \
  --name github-main \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:FOGUERAYAN/PROJET-Cloud_Computing_Group17:ref:refs/heads/main \
  --audiences api://AzureADTokenExchange
```

Le sujet limite l'accès au dépôt applicatif et à la branche `main` : un workflow d'un autre dépôt ou d'une autre branche n'obtient aucun jeton.

## À faire ensuite

1. Secrets GitHub du dépôt application : `AZURE_CLIENT_ID` (clientId de `id-cap90-github`), `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`. Ce ne sont pas des mots de passe, mais on les garde en secrets.
2. Variable GitHub `ACR_NAME` : nom de l'ACR sans `.azurecr.io` (fourni par Maroua).
3. Rôle `AcrPush` à attribuer au `principalId` de `id-cap90-github`, sur l'ACR :
   ```
   az role assignment create --assignee-object-id <principalId> --assignee-principal-type ServicePrincipal \
     --role AcrPush --scope <id de l'ACR>
   ```
4. Premier test : lancer `publish` à la main (`workflow_dispatch`) et vérifier que l'image `cap90:<sha>` apparaît dans l'ACR.

## Pour supprimer (fin du projet uniquement)

```
az group delete --name rg-cap90-ci
```
