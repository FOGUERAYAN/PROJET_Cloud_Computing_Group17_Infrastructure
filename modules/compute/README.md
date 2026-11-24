Module compute (P1) — à remplir en phase 2 :
- VM Linux (sans IP publique) dans snet-app, ajoutée au pool du Load Balancer
- identité managée fournie par le module security (Maroua) : variable app_identity_id
- cloud-init : installe Docker, se connecte à l'ACR via l'identité, lance l'image sur le port 8000
- Azure Function à minuteur (rappels + purge des annonces), code fourni par Hafsatou
