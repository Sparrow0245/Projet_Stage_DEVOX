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
TARGET_VHOST="/etc/apache2/sites-available/sentinelle.conf"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/4] Activation des modules Apache (Proxy, SSL, Rewrite)"
a2enmod rewrite ssl headers proxy proxy_http >/dev/null

echo
echo "[2/4] Création du dossier Web Root"
mkdir -p "${WEB_ROOT}"

echo
echo "[3/4] Génération de la configuration VirtualHost & Reverse Proxy"
cat << 'EOF' > "${TARGET_VHOST}"
<VirtualHost *:80>
    ServerName localhost

    # Emplacement du Frontend Vue.js
    DocumentRoot /var/www/html/sentinelle

    # Directives du Reverse Proxy pour l'API Backend Spring Boot (Port 8080)
    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Logs
    ErrorLog ${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

echo
echo "[4/4] Activation du site Sentinelle et redémarrage d'Apache"
a2dissite 000-default.conf >/dev/null || true
a2ensite sentinelle.conf >/dev/null

apache2ctl configtest
systemctl restart apache2

echo
echo "==============================================================="
echo " Apache configuré avec succès avec redirection Reverse Proxy /api"
echo "==============================================================="
