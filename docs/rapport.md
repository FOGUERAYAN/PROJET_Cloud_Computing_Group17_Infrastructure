# Cap90 – Rapport de rendu

Projet Cloud Computing, JUNIA ISEN, équipe 17. Rendu : 7 décembre 2026.

> Brouillon vivant. Les sections 2, 6, 9 et 10 sont rédigées par Rayan. Pour les autres, on garde ici les décisions prises, à reprendre par leur auteur.

## 1. Contexte et objectifs

*(Hafsatou)*

## 2. Vue d'ensemble de l'architecture

*(Rayan, à compléter avec le schéma `docs/diagrams/`)*

- Application Flask (Python 3.12, Gunicorn, port 8000) dans un conteneur Docker, exécutée sur une VM Azure derrière un Load Balancer, sonde de santé `GET /health`.
- Données : un compte de stockage `stcap90prodfrc` (Blob : `coffre`, `annonces-photos`, `medias-lille` ; Table : `profils`, `etapes`, `annonces`, `heures`).
- Réseau : VNet `10.0.0.0/16`, sous-réseau app `10.0.1.0/24` et sous-réseau data `10.0.2.0/24`.
- Authentification de l'application aux services Azure : identité managée (`DefaultAzureCredential`), sans clé ni mot de passe.
- Infrastructure décrite en Terraform, découpée en modules `network`, `compute`, `storage`, `security`, `monitoring`. L'état est conservé dans un compte de stockage distinct (remote state).
- Les noms partagés entre l'application et l'infrastructure sont fixés dans le contrat d'interface (README du dépôt infrastructure).

## 3. Conception du stockage

*(Hafsatou. Décisions de l'équipe à intégrer)*

- Réplication **ZRS** conservée : sa disponibilité en `francecentral` a été vérifiée par Godwin sur l'abonnement de l'équipe, sans restriction.
- Private endpoint pour le **Blob** et, sur proposition de Godwin, un second pour les **Tables**, afin que tout le trafic de données passe par `snet-data`, protégé par le même NSG.
- La variable racine `deployer_ips` est créée dans la PR de Hafsatou (sinon `tflint` signale une variable inutilisée). Les IP se saisissent **sans `/32`**, car Azure refuse ce suffixe dans `ip_rules`. La valeur est fournie hors Git (`TF_VAR_deployer_ips`).
- Hafsatou câble son module dans le `main.tf` racine, avec les noms de Godwin : `module.network.subnet_data_id`, `module.network.subnet_app_id` et `azurerm_resource_group.main`.

## 4. Conception du calcul

*(Godwin. Éléments déjà en place, à rédiger)*

- VM Ubuntu 24.04 Gen2 `Standard_F1als_v7` (la série B est bloquée sur Azure for Students), disque NVMe, sans IP publique, dans `snet-app` et membre du pool du Load Balancer.
- Pas de port 22 : clé SSH générée par Terraform (`tls_private_key`), accès d'urgence par la console série (boot diagnostics). La clé privée n'est que dans le state (backend distant protégé), jamais dans Git.
- Identité managée `SystemAssigned` en attendant le module `security` ; elle doit passer en `UserAssigned` (identité de Maroua) pour que les rôles Storage et Key Vault s'appliquent à la bonne identité.
- Phase de test : `cloud-init` installe Docker et lance nginx sur le port 8000 avec `/health`, pour valider toute la chaîne avant l'image Cap90.
- **Quota et VM Spot.** L'`apply` a créé le LB, la NAT et le service endpoint, mais pas la VM : l'abonnement Azure for Students a un quota de 0 vCPU sur la famille `Falsv7` (francecentral), la demande d'augmentation a été refusée automatiquement et les autres tailles sont soit sans quota, soit bloquées (`NotAvailableForSubscription`). Le plan ne détectait pas ce quota. Solution retenue (PR #18) : une VM **Spot** de même taille, qui consomme le quota *low-priority* (3 vCPU). Paramètres : `eviction_policy = "Deallocate"` (éviction = VM éteinte, pas supprimée, redémarrage par `az vm start`) et `max_bid_price = -1` (jamais plus que le prix normal).

## 5. Conception du réseau

*(Godwin. Décisions à intégrer)*

- Service endpoints et network policies sur `snet-data` : ajoutés dans la PR réseau de Godwin, qui **doit être mergée avant** celle du stockage, sinon l'`apply` du stockage échoue.
- Le NSG de `snet-data` protège les deux private endpoints (Blob et Table).
- **NSG `nsg-app` (sur `snet-app`)** : seul le port de l'application (8000, variable `app_port`) est ouvert depuis Internet. Aucun port SSH n'est ouvert ; les sondes du Load Balancer passent par la règle par défaut `AllowAzureLoadBalancerInBound`.
- **NSG `nsg-data` (sur `snet-data`)** : seul le port 443 est autorisé, et uniquement depuis `snet-app` (`10.0.1.0/24`). Une règle `Deny-VNet-Inbound` en priorité 4000 passe avant la règle par défaut `AllowVnetInBound` (65000) ; sans elle, tout le VNet pourrait joindre `snet-data`.
- **Entrée publique** : une IP publique Standard statique (nom DNS `cap90-prod-frc.francecentral.cloudapp.azure.com`) et un Load Balancer Standard. La règle `rule-http-80` envoie le port 80 public vers le port 8000 de la VM ; la sonde `probe-health` interroge `GET /health` sur le port 8000 et le LB n'envoie du trafic qu'aux VM qui répondent. Le Load Balancer et l'IP ne sont appliqués qu'avec la VM, pour ne pas payer sans backend.
- **Sortie Internet** : la VM n'a pas d'IP publique. Elle sort (installation de Docker, image de l'ACR) par une passerelle NAT Standard associée à `snet-app` uniquement ; `snet-data` n'en a pas besoin (private endpoints). La règle du LB désactive donc son propre SNAT sortant (`disable_outbound_snat = true`) : le Load Balancer et la NAT forment un ensemble qui doit être appliqué ensemble, sans quoi la VM n'a aucune sortie.
- **Administration de la VM sans SSH** : à préciser par Godwin (`az vm run-command`, console série ou Azure Bastion, ce dernier étant payant).

## 6. Ingénierie Cloud Native

*(Rayan)*

### 6.1 Organisation du code

Deux dépôts publics : l'application et l'infrastructure. Le développement est en trunk-based : branches courtes (`feat/…`, `fix/…`, `docs/…`, `ci/…`), messages en Conventional Commits, un modèle de Pull Request commun. L'application respecte les principes 12-Factor : toute la configuration passe par des variables d'environnement, aucune clé n'est écrite dans le code.

### 6.2 Intégration continue

| Dépôt | Job | Vérifications |
|---|---|---|
| Application | `lint-test` | `ruff check`, `ruff format --check`, `pytest` (233 tests) |
| Application | `docker-build` | construction de l'image, vérification qu'elle tourne en utilisateur non root, démarrage du conteneur puis `GET /health` = 200 |
| Application | `gitleaks` | recherche de secrets dans tout l'historique Git |
| Infrastructure | `terraform` | `terraform fmt -check`, `init -backend=false`, `validate`, `tflint` |
| Infrastructure | `gitleaks` | recherche de secrets |

Dépendances de développement à versions fixées (`requirements-dev.txt`) pour des résultats reproductibles. Un test qui ne trouverait aucun test fait échouer la CI.

### 6.3 Conteneur

Image `python:3.12.16-slim-trixie` à version exacte, utilisateur `cap90` sans privilèges, port 8000, `HEALTHCHECK` sur `/health`, `.dockerignore` présent. Aucune image `latest` : l'image publiée est taguée avec le SHA du commit.

### 6.4 Protection de `main` et gouvernance

Les retours de relecture sont écrits dans la review de la PR, avec des remarques bloquantes (à traiter avant merge) et non bloquantes (à prendre en compte ensuite). Plusieurs remarques de relecture ont déjà été reprises par leurs auteurs : par exemple, le NSG de `snet-data` proposé par Godwin répond à la remarque de Rayan sur la PR des service endpoints (autoriser le 443 depuis `snet-app`).


Règles sur les deux dépôts :

- Pull Request obligatoire, avec une approbation du code owner (fichier `CODEOWNERS`) ; les approbations sont invalidées par un nouveau commit.
- Checks obligatoires : `lint-test`, `docker-build`, `gitleaks` (application) ; `terraform`, `gitleaks` (infrastructure) ; branche à jour avec `main`.
- Force push et suppression de `main` interdits.
- Seul le mode « Squash and merge » est autorisé, et les branches sont supprimées après merge : un commit par PR sur `main`.

Le propriétaire des dépôts garde la possibilité de contourner ces règles pour ses propres PR, qu'il ne peut pas approuver lui-même.

### 6.5 Publication de l'image (déploiement continu)

Le workflow `publish.yml` publie l'image dans l'Azure Container Registry après une CI verte sur `main` (ou à la demande). L'authentification GitHub → Azure se fait par **OIDC** (`azure/login`), sans mot de passe : un identifiant fédéré limite l'accès au dépôt applicatif et à la branche `main`. Le workflow s'ignore tant que le nom de l'ACR n'est pas défini. Le détail des actions manuelles est dans [`oidc-github-azure.md`](oidc-github-azure.md).

*Captures d'écran à insérer : pipelines verts, règle de protection, PR en attente de review, réglages de merge, identifiant fédéré.*

## 7. Sécurité, gouvernance et supervision

*(Maroua. Décisions à intégrer)*

- L'ACR `acrcap90prodfrc` est créé dans le module `security` (sorties `acr_name` et `login_server`), utilisé par Rayan (variable `ACR_NAME` du workflow de publication, rôle `AcrPush` pour la CI) et par Godwin (VM).
- Rôles de l'identité de l'application sur le stockage : `Storage Blob Data Contributor`, `Storage Table Data Contributor` et `Storage Blob Delegator` (liens de partage de 24 h en User Delegation SAS).
- Key Vault en RBAC, restreint à `snet-app` et aux IP de l'équipe. Le service endpoint `Microsoft.KeyVault` a été ajouté sur `snet-app` (PR #16) ; le Key Vault doit déclarer ce sous-réseau dans ses règles réseau.
- `SECRET_KEY` de l'application injectée depuis le Key Vault ; chaîne de connexion Application Insights ; identité managée **user-assigned** (décision de Maroua) ; les rôles Storage sont attribués par le module de Hafsatou à partir de `module.security.app_identity_principal_id`.

## 8. Analyse des coûts

*(Maroua. Éléments déjà connus à intégrer)*

- Calcul : la VM est en Spot (même taille `Standard_F1als_v7`), nettement moins chère qu'une VM à la demande ; elle est aussi la seule option possible avec le quota de l'abonnement étudiant.

- Réseau : la passerelle NAT Standard coûte environ 33 $ par mois, plus son IP publique ; le Load Balancer Standard et son IP publique s'ajoutent. L'`apply` est fait avec la VM, puis un `destroy` est prévu après la correction, pour limiter la consommation du crédit Azure for Students.
- Alternative à étudier : une *outbound rule* sur le Load Balancer donnerait la sortie Internet sans passerelle NAT, pour un coût moindre, avec le risque d'épuisement des ports SNAT.
- Stockage : ZRS (plus cher que LRS), conservé après vérification de sa disponibilité.

## 9. Limites et enseignements tirés

*(Rayan, avec les retours de chacun)*

- **Droits sur l'annuaire Entra ID.** Sur Azure for Students, le compte est propriétaire de l'abonnement mais n'a aucun droit sur l'annuaire du tenant de l'école : `az ad app create` est refusé (*Insufficient privileges*). On ne peut donc pas créer l'application et le service principal habituels pour l'OIDC. **Alternative retenue** : une identité managée user-assigned (`id-cap90-github`) avec un identifiant fédéré GitHub. C'est une ressource Azure ordinaire, qui ne demande que les droits sur l'abonnement, et elle garde le principe d'une authentification sans mot de passe.
- **Protection de branche et dépôts privés.** Sur un compte GitHub gratuit, la protection de branche n'est pas disponible pour un dépôt privé. Les dépôts ont été rendus publics, après vérification qu'aucun secret ne figurait dans les fichiers ni dans l'historique.
- **Actions manuelles hors Terraform** : création du remote state et du groupe `rg-cap90-tfstate` (Godwin), groupe `rg-cap90-ci` et identité `id-cap90-github` (Rayan). Elles sont documentées dans le dépôt (`bootstrap-remote-state.md`, `oidc-github-azure.md`) et isolées des groupes gérés par Terraform pour ne pas être supprimées par un `destroy`.
- **Dépendances entre membres.** Le nom de l'ACR bloque à la fois la publication de l'image et la configuration de la VM ; la PR réseau doit être mergée avant celle du stockage. Un contrat d'interface écrit et mis à jour dès le début a limité les écarts de noms entre l'application et l'infrastructure, mais ces dépendances d'ordre restent à planifier.
- **Contrat d'interface.** Les noms de variables d'environnement de l'application ne correspondaient pas à ceux prévus au départ (`STORAGE_ACCOUNT_NAME` devenu `AZURE_STORAGE_ACCOUNT_NAME`, ajout de `STORAGE_MODE` et `SECRET_KEY`) : le contrat a été aligné sur le code.
- **Points de sécurité applicatifs restant à traiter** : pas de protection CSRF sur les formulaires et pas de cookie de session `Secure` ; le risque est limité (pas de mot de passe) mais à documenter.
- **Application exposée en HTTP clair.** L'entrée publique est le port 80 du Load Balancer, redirigé vers le port 8000 de la VM, sans TLS ni redirection vers HTTPS. C'est cohérent avec le périmètre du projet, mais un déploiement réel demanderait un certificat et un point d'entrée HTTPS (ou un service frontal dédié).
- **Règles de sortie par défaut.** Seules les règles entrantes sont restreintes par les NSG ; le trafic sortant reste ouvert (accès à l'ACR, à Internet).
- **Quota de l'abonnement et VM Spot.** Le quota de calcul à 0 sur la famille de VM choisie n'était visible qu'à l'`apply`. Avec une VM Spot, Azure peut éteindre la VM s'il manque de capacité : l'application est alors indisponible jusqu'à son redémarrage, ce qui est acceptable pour ce projet mais pas pour une production. Une VM à la demande ou un VMSS avec plusieurs instances serait préférable avec un quota normal.
- **Validation réelle.** Les vérifications faites en CI et en local (`terraform validate`, `tflint`, tests) ne remplacent pas un `apply` : la création des tables par l'API ARM et les liens de partage 24 h en User Delegation SAS ne seront confirmés qu'une fois l'infrastructure déployée.

## 10. Annexes

*(Rayan)*

### A. Actions manuelles réalisées sur Azure

| Date | Action | Auteur | Détail |
|---|---|---|---|
| 24/11/2026 | Remote state (groupe, compte de stockage, conteneur) | Godwin | [`bootstrap-remote-state.md`](bootstrap-remote-state.md) |
| 25/11/2026 | Tentative d'application Entra ID (refusée), puis groupe `rg-cap90-ci`, identité `id-cap90-github` et identifiant fédéré | Rayan | [`oidc-github-azure.md`](oidc-github-azure.md) |
| 27/11/2026 | `apply` partiel : LB, NAT et service endpoint Key Vault créés ; création de la VM refusée (quota 0 vCPU), test manuel d'une VM Spot dans un groupe temporaire `rg-test-spot` (supprimé), demande d'augmentation de quota refusée | Godwin | PR #15 et #18 |

### B. Usage d'assistants d'intelligence artificielle

Des assistants d'IA ont été utilisés pendant le projet (aide à la rédaction du code, de la configuration CI/CD et des scripts). Tout le code et toute la documentation ont été relus par un membre de l'équipe avant intégration. Deux commits de l'application portent un trailer `Co-Authored-By` correspondant à cet usage ; l'historique partagé n'a pas été réécrit.

*(À compléter avec le détail par membre.)*
