#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 05 - Configuration et activation d'Apache2 sur le Port 8080
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [05/09] Configuration du serveur Web Apache2 (Port 8080)"
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

WEB_ROOT="/var/www/html/sentinelle"

# 1. Ajout de la directive Listen 8080 dans ports.conf si absente
echo "[1/4] Configuration du port d'écoute Apache..."
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# 2. Création du VirtualHost dédié au port 8080
echo "[2/4] Création du VirtualHost sur le port 8080..."
cat <<EOF > /etc/apache2/sites-available/sentinelle-8080.conf
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot ${WEB_ROOT}

    <Directory ${WEB_ROOT}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/sentinelle_error.log
    CustomLog \${APACHE_LOG_DIR}/sentinelle_access.log combined
</VirtualHost>
EOF

# 3. Activation des modules et de la configuration du site
echo "[3/4] Activation des modules Apache et de la configuration..."
a2enmod headers rewrite alias &>/dev/null || true
a2ensite sentinelle-8080.conf &>/dev/null || true

# 4. Validation et rechargement
echo "[4/4] Test de syntaxe Apache et redémarrage..."
if apache2ctl configtest &>/dev/null; then
    systemctl restart apache2
    echo "[OK] Apache2 configuré et à l'écoute sur le port 8080."
else
    echo "[ERREUR] Erreur de syntaxe dans la configuration Apache !"
    exit 1
fi

echo "==============================================================="
echo " Serveur Web Apache2 configuré avec succès sur http://localhost:8080"
echo "==============================================================="
