#!/bin/bash
# Surveille en continu le journal d'une jail, extrait les IP en échec,
# compte les tentatives dans une fenêtre glissante et déclenche le ban.

ecrire_tentative() {
    local fichier="$1" ip="$2"
    echo "${ip} $(date +%s)" >> "$fichier"
}

demarrer_jail() {
    local fichier_conf="$1"
    # shellcheck disable=SC1090
    source "$fichier_conf"

    local fichier_tentatives="${BASE}/data/tentatives_${NOM}.db"
    touch "$fichier_tentatives"

    if [ ! -f "$JOURNAL" ]; then
        sentinelle_log "ERREUR" "Journal introuvable: ${JOURNAL} (jail=${NOM})"
        return 1
    fi

    tail -Fn0 "$JOURNAL" 2>/dev/null | while read -r ligne; do

        echo "$ligne" | grep -qE "$REGEX_ECHEC" || continue

        local ip
        ip=$(echo "$ligne" | grep -oE "$REGEX_IP" | head -n1)
        [ -z "$ip" ] && continue

        est_whitelist "$ip" && continue
        est_banni "$ip" && continue

        with_lock "${fichier_tentatives}.lock" ecrire_tentative "$fichier_tentatives" "$ip"

        local now cutoff nb
        now=$(date +%s)
        cutoff=$((now - FENETRE_TEMPS))
        nb=$(awk -v ip="$ip" -v c="$cutoff" '$1==ip && $2>=c' "$fichier_tentatives" | wc -l)

        if (( nb >= MAX_TENTATIVES )); then
            ban_ip "$ip" "$NOM"
        fi
    done
}
