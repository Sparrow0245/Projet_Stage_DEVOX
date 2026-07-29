#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache VirtualHost & Reverse Proxy Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Configuration Apache & Reverse Proxy API"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"

WEB_ROOT="/var/www/html/sentinelle"
VHOST_CONF="${APP_DIR}/config/apache/sentinelle.conf"
TARGET_VHOST="/etc/apache2/sites-available/sentinelle.conf"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/4] Activation des modules Apache (Proxy, SSL, Rewrite)"
a2enmod rewrite ssl headers proxy proxy_http >/dev/null

echo
echo "[2/4] Copie de la configuration VirtualHost"
cp "${VHOST_CONF}" "${TARGET_VHOST}"

echo
echo "[3/4] Activation du site Sentinelle"
a2dissite 000-default.conf >/dev/null || true
a2ensite sentinelle.conf >/dev/null

echo
echo "[4/4] Validation et redémarrage d'Apache"
apache2ctl configtest
systemctl restart apache2

echo
echo "==============================================================="
echo " Apache configuré avec succès avec redirection Reverse Proxy /api"
echo "==============================================================="
