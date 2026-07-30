#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache sur Port 8080 & Reverse Proxy pour Sentinelle V4
###############################################################################

set -euo pipefail

echo "=================================================="
echo " Configuration d'Apache2 (Port 8080) & Reverse Proxy"
echo "=================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Certificats SSL auto-signés
mkdir -p /etc/ssl/sentinelle
if [[ ! -f /etc/ssl/sentinelle/sentinelle.crt ]]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/ssl/sentinelle/sentinelle.key \
      -out /etc/ssl/sentinelle/sentinelle.crt \
      -subj "/C=FR/ST=Nord/L=Lille/O=Devox/OU=Sentinelle/CN=localhost"
    chmod 600 /etc/ssl/sentinelle/sentinelle.key
fi

# 2. Activation des modules Apache
a2enmod proxy proxy_http ssl rewrite

# 3. Ajout de l'écoute sur le port 8080 dans Apache
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# 4. Configuration VirtualHost sur les ports 80, 8080 et 443
cat << "EOF" > /etc/apache2/sites-available/sentinelle.conf
<VirtualHost *:80 *:8080>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass /api/ http://127.0.0.1:8081/api/
    ProxyPassReverse /api/ http://127.0.0.1:8081/api/
    ProxyPass /api http://127.0.0.1:8081/api
    ProxyPassReverse /api http://127.0.0.1:8081/api

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    SSLEngine on
    SSLCertificateFile /etc/ssl/sentinelle/sentinelle.crt
    SSLCertificateKeyFile /etc/ssl/sentinelle/sentinelle.key

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass /api/ http://127.0.0.1:8081/api/
    ProxyPassReverse /api/ http://127.0.0.1:8081/api/
    ProxyPass /api http://127.0.0.1:8081/api
    ProxyPassReverse /api http://127.0.0.1:8081/api

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>
</VirtualHost>
EOF

# 5. Activation et redémarrage
a2dissite 000-default.conf || true
a2ensite sentinelle.conf
systemctl restart apache2

echo "[OK] 05_apache.sh terminé avec succès."
