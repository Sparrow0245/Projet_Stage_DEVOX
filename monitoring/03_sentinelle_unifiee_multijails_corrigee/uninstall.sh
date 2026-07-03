#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en root (sudo ./uninstall.sh)"
    exit 1
fi

BASE="/opt/sentinelle"

systemctl stop sentinelle.service 2>/dev/null || true
systemctl disable sentinelle.service 2>/dev/null || true
rm -f /etc/systemd/system/sentinelle.service
rm -f /etc/logrotate.d/sentinelle
rm -f /usr/local/bin/sentinelle-ctl
systemctl daemon-reload

if [ -f "$BASE/data/bannis.db" ]; then
    while IFS=";" read -r ip ts jail; do
        [ -z "$ip" ] && continue
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null || true
    done < "$BASE/data/bannis.db"
fi

read -p "Supprimer ${BASE} et toutes les données (bans, logs) ? [o/N] " reponse
if [[ "$reponse" == "o" || "$reponse" == "O" ]]; then
    rm -rf "$BASE"
    echo "Supprimé."
else
    echo "Fichiers conservés dans ${BASE}, service désactivé."
fi
