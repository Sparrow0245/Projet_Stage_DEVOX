#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration Apache VirtualHost Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Configuration Apache Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

WEB_ROOT="/var/www/html/sentinelle"

VHOST_NAME="sentinelle.conf"

VHOST_PATH="/etc/apache2/sites-available/${VHOST_NAME}"

DOMAIN="sentinelle.local"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then

    echo "[ERREUR] Ce script doit être exécuté avec sudo."

    exit 1

fi



###############################################################################
# Vérification Apache
###############################################################################

echo "[1/7] Vérification Apache"


if ! command -v apache2ctl >/dev/null 2>&1
then

    echo "[ERREUR] Apache n'est pas installé."

    exit 1

fi



###############################################################################
# Vérification dossier web
###############################################################################

echo
echo "[2/7] Vérification dossier Web"



if [[ ! -d "${WEB_ROOT}" ]]
then

    echo "[ERREUR] Le dossier ${WEB_ROOT} n'existe pas."

    echo "Lancer d'abord 04_deploiement_web.sh"

    exit 1

fi



###############################################################################
# Génération VirtualHost
###############################################################################

echo
echo "[3/7] Création VirtualHost"



cat > "${VHOST_PATH}" <<EOF

<VirtualHost *:80>

    ServerName ${DOMAIN}

    DocumentRoot ${WEB_ROOT}


    <Directory ${WEB_ROOT}>

        Options Indexes FollowSymLinks

        AllowOverride All

        Require all granted

    </Directory>


    ErrorLog \${APACHE_LOG_DIR}/sentinelle_error.log

    CustomLog \${APACHE_LOG_DIR}/sentinelle_access.log combined


</VirtualHost>

EOF



echo "[OK] VirtualHost créé : ${VHOST_PATH}"



###############################################################################
# Activation modules
###############################################################################

echo
echo "[4/7] Activation modules Apache"



a2enmod rewrite >/dev/null

a2enmod headers >/dev/null



###############################################################################
# Activation site
###############################################################################

echo
echo "[5/7] Activation du site"



a2ensite "${VHOST_NAME}" >/dev/null



if [[ -e "/etc/apache2/sites-enabled/000-default.conf" ]]
then

    echo "[INFO] Désactivation du site par défaut"

    a2dissite 000-default.conf >/dev/null || true

fi



###############################################################################
# Configuration résolution locale
###############################################################################

echo
echo "[6/7] Configuration DNS local"



if ! grep -q "${DOMAIN}" /etc/hosts
then

    echo "127.0.0.1 ${DOMAIN}" >> /etc/hosts

    echo "[OK] Ajout ${DOMAIN}"

else

    echo "[OK] ${DOMAIN} déjà présent"

fi



###############################################################################
# Test et redémarrage
###############################################################################

echo
echo "[7/7] Validation Apache"



apache2ctl configtest



systemctl restart apache2



if systemctl is-active --quiet apache2
then

    echo
    echo "[OK] Apache fonctionne"

else

    echo
    echo "[ERREUR] Apache ne démarre pas"

    exit 1

fi



echo
echo "==============================================================="
echo " Apache configuré avec succès"
echo
echo " URL : http://${DOMAIN}"
echo " Racine : ${WEB_ROOT}"
echo "==============================================================="
