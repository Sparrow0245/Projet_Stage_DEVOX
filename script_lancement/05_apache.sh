#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache & Reverse Proxy pour Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Configuration Apache HTTP/HTTPS & Reverse Proxy"
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/4] Activation des modules Apache nécessaires"
a2enmod proxy proxy_http rewrite ssl headers >/dev/null 2>&1 || true

echo
echo "[2/4] Génération du certificat SSL auto-signé"
mkdir -p /etc/ssl/sentinelle
if [ ! -f /etc/ssl/sentinelle/sentinelle.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/sentinelle/sentinelle.key \
        -out /etc/ssl/sentinelle/sentinelle.crt \
        -subj "/C=FR/ST=Nord/L=Lille/O=Devox/OU=IT/CN=localhost" >/dev/null 2>&1
fi

echo
echo "[3/4] Création du VirtualHost /etc/apache2/sites-available/sentinelle.conf"
cat << 'EOF' > /etc/apache2/sites-available/sentinelle.conf
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/sentinelle

    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/sentinelle

    SSLEngine on
    SSLCertificateFile /etc/ssl/sentinelle/sentinelle.crt
    SSLCertificateKeyFile /etc/ssl/sentinelle/sentinelle.key

    ProxyPreserveHost On
    ProxyRequests Off

    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/sentinelle_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_ssl_access.log combined
</VirtualHost>
EOF

echo
echo "[4/4] Activation de la configuration Apache"
a2dissite 000-default.conf >/dev/null 2>&1 || true
a2ensite sentinelle.conf >/dev/null 2>&1 || true
systemctl restart apache2

echo
echo "==============================================================="
echo " Apache & Reverse Proxy configurés avec succès"
echo "==============================================================="
