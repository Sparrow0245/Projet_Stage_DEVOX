#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Désinstallation complète de Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Désinstallation Sentinelle V4"
echo "==============================================================="

SENTINELLE_DIR="/opt/sentinelle"
WEB_ROOT="/var/www/html/sentinelle"
SYSTEMD_DIR="/etc/systemd/system"
VHOST_PATH="/etc/apache2/sites-available/sentinelle.conf"
DB_NAME="sentinelle"
DB_USER="sentinelle"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

read -r -p "Confirmer la désinstallation de Sentinelle V4 ? (taper OUI) : " CONFIRM
if [[ "${CONFIRM}" != "OUI" ]]; then
    echo "[INFO] Désinstallation annulée."
    exit 0
fi

echo
echo "[1/5] Arrêt et suppression des services systemd"
systemctl stop sentinelle-backend.service sentinelle-monitor.timer || true
systemctl disable sentinelle-backend.service sentinelle-monitor.timer || true

rm -f "${SYSTEMD_DIR}/sentinelle-backend.service" \
      "${SYSTEMD_DIR}/sentinelle-monitor.service" \
      "${SYSTEMD_DIR}/sentinelle-monitor.timer"
systemctl daemon-reload

echo
echo "[2/5] Suppression VirtualHost Apache"
a2dissite sentinelle.conf >/dev/null 2>&1 || true
rm -f "${VHOST_PATH}"
a2ensite 000-default.conf >/dev/null 2>&1 || true
systemctl restart apache2 || true

echo
echo "[3/5] Nettoyage répertoires Web et /opt"
rm -rf "${WEB_ROOT}" "${SENTINELLE_DIR}" /var/log/sentinelle /tmp/sentinelle

echo
echo "[4/5] Suppression Base de Données"
mysql <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
rm -f /etc/mysql/sentinelle.cnf

echo
echo "==============================================================="
echo " Désinstallation Sentinelle V4 terminée"
echo "==============================================================="
