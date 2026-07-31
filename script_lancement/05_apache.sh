#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache2 - Sentinelle V4
###############################################################################

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

VHOST_CONF="/etc/apache2/sites-available/sentinelle.conf"

echo "[1/3] Configuration du port 8080"
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

echo "[2/3] Génération du VirtualHost sur /var/www/html"
cat <<EOF > "${VHOST_CONF}"
<VirtualHost *:8080>
    ServerAdmin admin@sentinelle.local
    DocumentRoot /var/www/html
    DirectoryIndex index.php index.html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /sentinelle /var/www/html/sentinelle

    ErrorLog \${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog \${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

echo "[3/3] Activation et redémarrage d'Apache"
rm -f /var/www/html/index.html
a2dissite 000-default.conf 2>/dev/null || true
a2ensite sentinelle.conf
systemctl restart apache2

echo "==============================================================="
echo " Apache2 reconfiguré sur http://localhost:8080/"
echo "==============================================================="
