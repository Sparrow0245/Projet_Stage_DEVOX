#!/bin/bash
# Installation de Sentinelle. À lancer depuis le dossier extrait de l'archive.
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté en root (sudo ./install.sh)"
    exit 1
fi

DIR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="/opt/sentinelle"

mkdir -p "$BASE"/{config/jails.d,lib,data,logs}

cp -r "$DIR_SOURCE"/config/* "$BASE/config/"
cp -r "$DIR_SOURCE"/lib/* "$BASE/lib/"
cp "$DIR_SOURCE/sentinelle.sh" "$BASE/sentinelle.sh"
cp "$DIR_SOURCE/sentinelle-ctl.sh" "$BASE/sentinelle-ctl.sh"

touch "$BASE/data/bannis.db"

chmod +x "$BASE/sentinelle.sh" "$BASE/sentinelle-ctl.sh" "$BASE"/lib/*.sh
chown -R root:root "$BASE"
chmod -R 750 "$BASE"

ln -sf "$BASE/sentinelle-ctl.sh" /usr/local/bin/sentinelle-ctl

cp "$DIR_SOURCE/systemd/sentinelle.service" /etc/systemd/system/sentinelle.service
cp "$DIR_SOURCE/systemd/sentinelle.logrotate" /etc/logrotate.d/sentinelle

systemctl daemon-reload
systemctl enable sentinelle.service

echo ""
echo "Installation terminée dans ${BASE}"
echo ""
echo "Vérifie/adapte AVANT de démarrer :"
echo "  - ${BASE}/config/jails.d/ssh.conf  (chemin du journal auth.log)"
echo "  - ${BASE}/config/liste_blanche.conf"
echo ""
echo "Démarrer     : systemctl start sentinelle"
echo "Statut       : systemctl status sentinelle"
echo "Logs         : journalctl -u sentinelle -f"
echo "Bans actuels : sentinelle-ctl status"
