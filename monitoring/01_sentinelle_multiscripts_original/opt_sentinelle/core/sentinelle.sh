#!/bin/bash
# CORRIGÉ : l'original relisait tout le journal à chaque itération (cat +
# boucle toutes les 2s), recomptant indéfiniment les mêmes lignes.
# Passage en lecture en flux (tail -Fn0) : chaque ligne n'est traitée
# qu'une seule fois, au moment où elle est écrite dans le journal.

BASE="/opt/sentinelle"

source $BASE/config/sentinelle.conf
source $BASE/detection/detecteur.sh
source $BASE/detection/correlation.sh
source $BASE/response/gestion_ban.sh
source $BASE/security/whitelist.sh

tail -Fn0 /var/log/auth.log | while read -r ligne; do
    ip=$(detecter_ips "$ligne")
    [ -z "$ip" ] && continue

    is_whitelisted "$ip" && continue

    # CORRIGÉ : l'original ne remplissait jamais events.log, donc
    # correlation.sh comptait toujours 0. On journalise ici chaque
    # détection avec un timestamp pour permettre un comptage réel.
    echo "$(date +%s) $ip" >> $BASE/data/events.log

    score=$(correlate "$ip" | cut -d':' -f2)

    if (( score > SEUIL_SCORE )); then
        ban_ip "$ip"
    fi
done
