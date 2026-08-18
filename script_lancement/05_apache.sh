#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache2 - Sentinelle V4 (Port 8080)
###############################################################################

echo ">>> Configuration d'Apache et du Reverse Proxy sur le port 8080..."

# Activation des modules Apache
sudo a2enmod rewrite proxy proxy_http

# Configuration d'Apache sur le port 8080
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" | sudo tee -a /etc/apache2/ports.conf > /dev/null
fi

# Écriture du VirtualHost sur le port 8080
cat << 'EOF' | sudo tee /etc/apache2/sites-available/sentinelle.conf > /dev/null
<VirtualHost *:8080>
    ServerName localhost
    DocumentRoot /var/www/html/sentinelle

    <Directory /var/www/html/sentinelle>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Redirection de l'API vers Spring Boot sur le port 8081
    ProxyPreserveHost On
    ProxyPass /api/ http://127.0.0.1:8081/api/
    ProxyPassReverse /api/ http://127.0.0.1:8081/api/
    ProxyPass /api http://127.0.0.1:8081/api
    ProxyPassReverse /api http://127.0.0.1:8081/api

    ErrorLog ${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog ${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

# Nettoyage automatique des caractères CRLF Windows dans la config
sudo sed -i 's/\r$//' /etc/apache2/sites-available/sentinelle.conf

# Activation du site et redémarrage d'Apache
sudo a2dissite 000-default.conf 2>/dev/null || true
sudo a2ensite sentinelle.conf
sudo systemctl restart apache2

echo "[OK] Apache configuré sur le port 8080 avec Reverse Proxy vers le port 8081."
