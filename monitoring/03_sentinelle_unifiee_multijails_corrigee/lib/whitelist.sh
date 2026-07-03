#!/bin/bash
# Vérification de whitelist par correspondance EXACTE ou CIDR
# (corrige le bug de "grep -q" du script d'origine, qui faisait
# une correspondance partielle et pouvait whitelister des IP non voulues)

ip_vers_entier() {
    local IFS=.
    local a b c d
    read -r a b c d <<< "$1"
    echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

ip_dans_cidr() {
    local ip="$1" cidr="$2"
    local reseau masque
    IFS="/" read -r reseau masque <<< "$cidr"

    local ip_dec reseau_dec mask_dec
    ip_dec=$(ip_vers_entier "$ip")
    reseau_dec=$(ip_vers_entier "$reseau")
    mask_dec=$(( 0xFFFFFFFF << (32 - masque) & 0xFFFFFFFF ))

    (( (ip_dec & mask_dec) == (reseau_dec & mask_dec) ))
}

est_whitelist() {
    local ip="$1"
    local ligne

    [ -f "$LISTE_BLANCHE" ] || return 1

    while IFS= read -r ligne; do
        ligne="${ligne%%#*}"
        ligne="$(echo -n "$ligne" | xargs)"
        [ -z "$ligne" ] && continue

        if [[ "$ligne" == *"/"* ]]; then
            [[ "$ip" == *.* ]] && ip_dans_cidr "$ip" "$ligne" && return 0
        elif [[ "$ip" == "$ligne" ]]; then
            return 0
        fi
    done < "$LISTE_BLANCHE"

    return 1
}
