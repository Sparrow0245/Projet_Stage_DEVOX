#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache2 - Sentinelle V4
###############################################################################

echo ">>> Configuration d'Apache et du Reverse Proxy..."

# Enable required Apache modules
sudo a2enmod rewrite proxy proxy_http

# Ensure Apache listens ONLY on port 80
sudo sed -i 's/Listen 8080//g' /etc/apache2/ports.conf 2>/dev/null || true

# Write Sentinelle VirtualHost configuration
cat << 'EOF' | sudo tee /etc/apache2/sites-available/sentinelle.conf > /dev/null
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Redirection de l'API vers Spring Boot
    ProxyPreserveHost On
    ProxyPass /api http://127.0.0.1:8080/api
    ProxyPassReverse /api http://127.0.0.1:8080/api

    ErrorLog ${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

# Enable site and restart service
sudo a2dissite 000-default.conf 2>/dev/null || true
sudo a2ensite sentinelle.conf
sudo systemctl restart apache2

echo "[OK] Apache configuré sur le port 80 avec Reverse Proxy vers 8080."
