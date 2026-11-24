# Contribuer au projet

Règles de travail de l'équipe 17 (Godwin, Maroua, Hafsatou, Rayan). Elles s'appliquent aux deux dépôts.

## Branches

Stratégie trunk-based : `main` est la seule branche longue et reste toujours déployable.

- Une branche courte par tâche, créée depuis `main` à jour, et supprimée après le merge.
- Nommage : `feat/<sujet>`, `fix/<sujet>`, `docs/<sujet>`, `ci/<sujet>`, `chore/<sujet>`.
  Exemples : `feat/module-network`, `fix/nsg-port-8000`, `docs/section-6`.
- Aucun push direct sur `main` une fois la protection activée : tout passe par une Pull Request.

## Messages de commit

Format [Conventional Commits](https://www.conventionalcommits.org/fr/) : `type(portée): description à l'impératif`.

| Type | Usage |
|---|---|
| `feat` | nouvelle fonctionnalité ou nouvelle ressource |
| `fix` | correction |
| `docs` | documentation, rapport, schémas |
| `ci` | workflows GitHub Actions |
| `refactor` | réorganisation sans changement de comportement |
| `test` | ajout ou modification de tests |
| `chore` | maintenance (.gitignore, dépendances…) |

Exemples : `feat(network): ajoute le VNet et les sous-réseaux app et data`, `fix(app): corrige la route /health`.

## Pull Requests

1. La CI doit être verte (lint, tests, validation Terraform, détection de secrets).
2. Une approbation d'un autre membre est nécessaire.
3. Les fichiers partagés de l'infrastructure (`main.tf`, `outputs.tf`, `envs/prod.tfvars`) sont relus par Godwin.
4. Merge en « Squash and merge », avec un titre de PR au format Conventional Commits.

## Règles de sécurité

- Aucun secret dans le code, dans un fichier `.tfvars` ou dans l'historique Git. Les secrets vont dans Azure Key Vault ; la CI les récupère via les secrets GitHub.
- Si un secret est poussé par erreur : le révoquer immédiatement côté Azure, puis prévenir l'équipe (le supprimer du dernier commit ne suffit pas).

## Terraform

- Chacun travaille dans son module. Seul Godwin lance `terraform apply`, depuis `main` à jour ; les autres lancent `terraform plan` sur leur branche.
- `terraform fmt -recursive` avant chaque commit.
- `terraform destroy` quand l'équipe ne travaille pas, pour économiser les crédits Azure for Students.
