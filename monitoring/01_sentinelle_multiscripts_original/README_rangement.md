# Note sur le rangement des fichiers - Version 1

Le document source (Proposition_1_de_solutions_de_monitoring_avancees.md)
donnait l'arborescence suivante :

    /opt/sentinelle/
    ├── core/
    ├── detection/
    ├── response/
    ├── security/
    ├── performance/
    ├── reporting/
    ├── system/
    ├── config/
    ├── data/
    ├── logs/

...mais ne précisait PAS explicitement dans quel sous-dossier chacun des
10 scripts numérotés devait être placé. Le rangement appliqué ici est une
interprétation d'après le nom/rôle de chaque script :

- installation.sh  -> racine (script d'installation, hors arborescence)
- sentinelle.sh     -> core/ (orchestrateur principal)
- detecteur.sh      -> detection/
- correlation.sh    -> detection/
- gestion_ban.sh    -> response/
- notification.sh   -> system/
- whitelist.sh      -> security/
- log.sh            -> system/
- scheduler.sh      -> system/
- quarantaine.sh    -> response/

Les dossiers performance/ et reporting/ restent vides : le document
original ne leur associait aucun script.

## Corrections apportées et raisonnement

1. core/sentinelle.sh — relisait tout /var/log/auth.log à chaque itération
   (toutes les 2s), ce qui recomptait indéfiniment les mêmes vieilles lignes
   -> correction : passage en lecture en flux (tail -Fn0), une ligne traitée
   une seule fois.

2. detection/correlation.sh — comptait les occurrences dans data/events.log,
   fichier que rien n'écrivait dans le script original -> le score restait
   toujours à 0 et aucun ban ne pouvait jamais se déclencher.
   Correction : sentinelle.sh écrit désormais chaque IP détectée dans
   events.log (avec timestamp), et correlation.sh calcule un score sur une
   fenêtre glissante (FENETRE_TEMPS) au lieu de compter sur toute la durée
   de vie du fichier.

3. Seuil de déclenchement — le script original comparait un score à 80,
   mais un score = nombre brut de tentatives (donc il aurait fallu 81
   échecs avant tout ban : beaucoup trop permissif pour du brute-force).
   Correction : score = nombre de tentatives dans la fenêtre * 20, avec
   SEUIL_SCORE=80 -> déclenchement après MAX_TENTATIVES=5 échecs par
   défaut (paramétrable dans config/sentinelle.conf, fichier ajouté car
   absent de l'original).

4. security/whitelist.sh — utilisait "grep -q" (correspondance partielle :
   "192.168.0.1" whitelistait aussi "192.168.0.100") -> correction :
   "grep -qxF" (correspondance exacte de ligne entière).

5. response/gestion_ban.sh — n'enregistrait pas de timestamp de ban et
   pouvait dupliquer une règle iptables si appelée deux fois pour la même
   IP -> correction : vérification d'idempotence + timestamp ajouté au
   format "ip;timestamp" (nécessaire pour permettre l'expiration).
   Une fonction unban_ip() et unban_expires() ont été ajoutées : sans elles,
   aucune IP bannie ne pouvait jamais être débannie automatiquement.

6. system/scheduler.sh — était un script vide (juste "true", aucun effet)
   -> correction : boucle appelant unban_expires() toutes les 60s. Sans ce
   script actif en tâche de fond, les corrections du point 5 restent sans
   effet (le ban ne serait jamais levé).

7. response/quarantaine.sh — ajout d'une vérification d'idempotence
   (évite d'empiler des règles iptables identiques à chaque appel).

## Non modifiés

- installation.sh (complété uniquement pour créer config/sentinelle.conf)
- system/notification.sh, system/log.sh, detection/detecteur.sh :
  aucun bug identifié, laissés tels quels.

## Point non vérifiable par moi

Je n'ai pas de moyen de savoir si l'intention originale de "correlation.sh"
était de combiner plusieurs signaux (pas seulement un compteur d'échecs) —
le document ne le précise pas. Je ne peux donc pas affirmer que le calcul
de score corrigé ci-dessus correspond à une intention initiale plus riche ;
je corrige seulement le fait que le score original ne pouvait jamais
dépasser 0 dans la pratique.
