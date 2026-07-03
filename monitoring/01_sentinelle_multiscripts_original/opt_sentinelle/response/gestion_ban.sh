# CORRIGÉ : l'original n'enregistrait ni timestamp (donc aucune expiration
# possible) ni vérification d'idempotence (une règle iptables identique
# pouvait être empilée à chaque appel pour la même IP). Ajout de
# unban_ip() et unban_expires(), absentes de l'original : sans elles,
# une IP bannie l'était définitivement, sans aucun mécanisme de levée.

ban_ip() {
    ip="$1"

    grep -q "^$ip;" /opt/sentinelle/data/bannis.db 2>/dev/null && return

    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -A INPUT -s "$ip" -j DROP

    echo "$ip;$(date +%s)" >> /opt/sentinelle/data/bannis.db
}

unban_ip() {
    ip="$1"
    iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
    sed -i "/^$ip;/d" /opt/sentinelle/data/bannis.db
}

unban_expires() {
    now=$(date +%s)
    [ -f /opt/sentinelle/data/bannis.db ] || return
    while IFS=";" read -r ip ts; do
        [ -z "$ip" ] && continue
        if (( now - ts > DUREE_BAN )); then
            unban_ip "$ip"
        fi
    done < /opt/sentinelle/data/bannis.db
}
