# Module `network`

**Responsable :** Godwin

**Contenu prévu :** VNet 10.0.0.0/16, sous-réseaux app (10.0.1.0/24) et data (10.0.2.0/24), NSG en moindre privilège, IP publique, Load Balancer Standard (sonde /health), passerelle NAT.

Fichiers attendus : `main.tf`, `variables.tf`, `outputs.tf`.
Toutes les ressources reçoivent la variable `tags` (owner, project, environment).
