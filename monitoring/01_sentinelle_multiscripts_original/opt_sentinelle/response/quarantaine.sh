# CORRIGÉ : ajout d'une vérification d'idempotence, absente de l'original,
# qui empilait une règle iptables identique à chaque appel pour la même IP.
quarantine() {
    ip="$1"
    iptables -C INPUT -s "$ip" -j DROP 2>/dev/null || iptables -I INPUT -s "$ip" -j DROP
    echo "$ip;$(date +%s)" >> /opt/sentinelle/data/bannis.db
}
