#!/bin/bash

source ./configuration.conf

mkdir -p /opt/sentinelle
touch "$BASE_BAN" /tmp/tentatives.tmp

log() {
    echo "$(date -Iseconds) [$1] $2" >> "$LOG"
}

est_whitelist() {
    # CORRIGÉ : grep -q faisait une correspondance partielle. -qxF impose
    # une correspondance exacte de la ligne entière.
    grep -qxF "$1" "$LISTE_BLANCHE"
}

est_banni() {
    grep -q "^$1;" "$BASE_BAN"
}

ajouter_tentative() {
    echo "$1 $(date +%s)" >> /tmp/tentatives.tmp
}

compter_tentatives() {
    ip="$1"
    now=$(date +%s)
    cutoff=$((now - FENETRE_TEMPS))

    awk -v ip="$ip" -v c="$cutoff" '$1==ip && $2>=c' /tmp/tentatives.tmp | wc -l
}

ban_ip() {
    ip="$1"

    est_banni "$ip" && return

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || \
    iptables -A INPUT -s "$ip" -j DROP

    echo "$ip;$(date +%s)" >> "$BASE_BAN"

    log "WARN" "BAN IP $ip"
}

unban_expired() {
    now=$(date +%s)

    while IFS=";" read ip time; do
        if (( now - time > DUREE_BAN )); then
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            sed -i "\|$ip;|d" "$BASE_BAN"
            log "INFO" "UNBAN IP $ip"
        fi
    done < "$BASE_BAN"
}

tail -Fn0 "$FICHIER_JOURNAL" | while read line; do

    ip=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")

    [ -z "$ip" ] && continue
    est_whitelist "$ip" && continue

    # CORRIGÉ : l'original passait déjà un timestamp dans l'argument alors
    # que la fonction en ajoute un second -> lignes à 3 champs, comptage
    # cassé. On ne passe que l'IP.
    ajouter_tentative "$ip"

    if [ "$(compter_tentatives "$ip")" -ge "$MAX_TENTATIVES" ]; then
        ban_ip "$ip"
    fi

    unban_expired

done
