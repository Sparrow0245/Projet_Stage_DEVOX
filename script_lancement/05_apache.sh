#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache & Reverse Proxy pour Sentinelle V4
###############################################################################

# 05_apache.sh - Configuration d'Apache2 et du Reverse Proxy pour Sentinelle V4

echo "=================================================="
echo " Configuration d'Apache2 & Reverse Proxy"
echo "=================================================="

sudo a2enmod proxy proxy_http ssl rewrite

sudo bash -c 'cat << "EOF" > /etc/apache2/sites-available/sentinelle.conf
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/sentinelle

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/
    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/sentinelle

    SSLEngine on
    SSLCertificateFile /etc/ssl/sentinelle/sentinelle.crt
    SSLCertificateKeyFile /etc/ssl/sentinelle/sentinelle.key

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/
    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    <Directory /var/www/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF'

sudo a2dissite 000-default.conf
sudo a2ensite sentinelle.conf
sudo systemctl restart apache2

echo "[OK] 05_apache.sh terminé avec succès."
