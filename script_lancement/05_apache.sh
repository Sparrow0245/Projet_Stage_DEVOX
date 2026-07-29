#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache VirtualHost & Reverse Proxy HTTPS Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Configuration Apache & Reverse Proxy API (HTTP/HTTPS)"
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
echo "[1/5] Activation des modules Apache (Proxy, SSL, Rewrite)"
a2enmod rewrite ssl headers proxy proxy_http >/dev/null

echo
echo "[2/5] Préparation du dossier Web Root et index.html"
mkdir -p "${WEB_ROOT}"

if [[ ! -f "${WEB_ROOT}/index.html" ]]; then
    cat << 'EOF' > "${WEB_ROOT}/index.html"
<!DOCTYPE html>
<html lang="fr">
<head><title>Sentinelle V4</title></head>
<body><h1>Sentinelle V4 - Dashboard</h1></body>
</html>
EOF
fi

echo
echo "[3/5] Génération du VirtualHost Apache (Ports 80 & 443 HTTPS)"
cat << 'EOF' > "${TARGET_VHOST}"
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/
    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost _default_:443>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/
    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

echo
echo "[4/5] Activation du site Sentinelle"
a2dissite 000-default.conf default-ssl.conf >/dev/null || true
a2ensite sentinelle.conf >/dev/null

echo
echo "[5/5] Validation et redémarrage d'Apache"
apache2ctl configtest
systemctl restart apache2

echo "==============================================================="
echo " Apache HTTP/HTTPS configuré avec succès"
echo "==============================================================="
