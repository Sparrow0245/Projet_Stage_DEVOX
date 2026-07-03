#!/bin/bash
# Gestion des bannissements : ajout/suppression de règles iptables,
# écriture verrouillée dans la base, expiration automatique et
# restauration des bans au démarrage (persistance après reboot).

est_banni() {
    local ip="$1"
    grep -q "^${ip};" "$BASE_BAN" 2>/dev/null
}

ecrire_ligne_ban() {
    local ip="$1" jail="$2"
    echo "${ip};$(date +%s);${jail}" >> "$BASE_BAN"
}

supprimer_ligne_ban() {
    local ip="$1"
    sed -i "/^${ip};/d" "$BASE_BAN"
}

ban_ip() {
    local ip="$1" jail="$2"

    est_whitelist "$ip" && return 0
    est_banni "$ip" && return 0

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP

    with_lock "${BASE_BAN}.lock" ecrire_ligne_ban "$ip" "$jail"

    sentinelle_log "WARN" "BAN ${ip} (jail=${jail})"
}

unban_ip() {
    local ip="$1"

    iptables -D INPUT -s "$ip" -j DROP 2>/dev/null

    with_lock "${BASE_BAN}.lock" supprimer_ligne_ban "$ip"

    sentinelle_log "INFO" "UNBAN ${ip}"
}

unban_expires() {
    local now ip ts jail duree
    now=$(date +%s)
    duree="${DUREE_BAN:-3600}"

    [ -f "$BASE_BAN" ] || return 0

    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        if (( now - ts > duree )); then
            unban_ip "$ip"
        fi
    done < "$BASE_BAN"
}

# Réapplique les règles iptables pour les IP encore bannies dans bannis.db.
# Ne touche à aucune autre règle du pare-feu (pas de iptables-restore global).
restaurer_bans() {
    [ -f "$BASE_BAN" ] || return 0
    local ip ts jail
    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP
    done < "$BASE_BAN"
    sentinelle_log "INFO" "Règles restaurées au démarrage depuis ${BASE_BAN}"
}
