# Corrections apportées - Version 2

## 1. ajouter_tentative() — bug de double timestamp

Original :
    ajouter_tentative() { echo "$1 $(date +%s)" >> /tmp/tentatives.tmp; }
    ...
    ajouter_tentative "$ip $(date +%s)"

L'appel passait déjà "$ip $(date +%s)" comme argument unique, et la
fonction ajoutait un second "$(date +%s)" -> chaque ligne de
tentatives.tmp avait 3 champs (ip, timestamp1, timestamp2) au lieu de 2.
compter_tentatives() utilise ensuite "awk '$1==ip && $2>=c'", qui
comparait le timestamp1 (et non l'IP) en $1 dans certains cas et cassait
le comptage -> le seuil MAX_TENTATIVES n'était plus fiable.

Correction : l'appel devient ajouter_tentative "$ip" (la fonction
génère elle-même son timestamp, comme prévu par sa définition).

## 2. est_whitelist() — correspondance partielle au lieu d'exacte

Original : grep -q "$1" "$LISTE_BLANCHE"
-> "192.168.0.1" dans la whitelist matchait aussi "192.168.0.100" ou
"10.192.168.0.5" (n'importe quelle ligne CONTENANT la chaîne).

Correction : grep -qxF "$1" "$LISTE_BLANCHE" (correspondance
exacte de la ligne entière, pas de sous-chaîne).

## Non modifié, limite connue et assumée

unban_expired() est appelée à chaque ligne de log lue (donc à chaque
tentative de connexion SSH), pas à intervalle régulier. Ce n'est pas un
bug de correction (le résultat reste correct), juste un choix
d'implémentation qui relit tout bannis.db plus souvent que nécessaire
sur un serveur à fort trafic SSH. Je ne l'ai pas modifié car ce n'était
pas une erreur fonctionnelle, seulement un point d'efficacité — je le
signale pour rester précis sur ce qui a été corrigé et ce qui ne l'a pas
été.
