# Module `compute`

**Responsable :** Godwin

**Contenu prévu :** VM Linux avec identité managée (cloud-init : Docker + conteneur de l'application sur le port 8000), évolution possible en VMSS, Azure Function (plan Consommation, Python).

Fichiers attendus : `main.tf`, `variables.tf`, `outputs.tf`.
Toutes les ressources reçoivent la variable `tags` (owner, project, environment).
