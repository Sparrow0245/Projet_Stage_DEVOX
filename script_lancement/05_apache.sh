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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


SOURCE_VHOST="${BASE_DIR}/monitoring/apache/sentinelle.conf"

APACHE_AVAILABLE="/etc/apache2/sites-available"

VHOST_NAME="sentinelle.conf"

VHOST_PATH="${APACHE_AVAILABLE}/${VHOST_NAME}"

HOST_ENTRY="127.0.0.1 sentinelle.local"



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

echo "[1/6] Vérification Apache"


if ! command -v apache2ctl >/dev/null 2>&1
then

    echo "[ERREUR] Apache n'est pas installé."
    exit 1

fi



###############################################################################
# Vérification fichier VirtualHost
###############################################################################

echo
echo "[2/6] Vérification VirtualHost"


if [[ ! -f "${SOURCE_VHOST}" ]]
then

    echo "[ERREUR] Fichier absent : ${SOURCE_VHOST}"
    echo "Créer monitoring/apache/sentinelle.conf avant de continuer."

    exit 1

fi



###############################################################################
# Installation VirtualHost
###############################################################################

echo
echo "[3/6] Installation VirtualHost"


cp "${SOURCE_VHOST}" "${VHOST_PATH}"



###############################################################################
# Activation modules Apache
###############################################################################

echo
echo "[4/6] Activation modules"



a2enmod rewrite >/dev/null


a2enmod headers >/dev/null



###############################################################################
# Activation site
###############################################################################

echo
echo "[5/6] Activation du site"



a2ensite "${VHOST_NAME}" >/dev/null



if [[ -e "/etc/apache2/sites-enabled/000-default.conf" ]]
then

    echo "[INFO] Désactivation site par défaut"


    a2dissite 000-default.conf >/dev/null || true

fi



###############################################################################
# Configuration hosts
###############################################################################

echo
echo "[6/6] Configuration résolution locale"



if ! grep -q "sentinelle.local" /etc/hosts
then

    echo "${HOST_ENTRY}" >> /etc/hosts

    echo "[OK] Entrée ajoutée dans /etc/hosts"

else

    echo "[OK] Entrée déjà présente"

fi



###############################################################################
# Test configuration
###############################################################################

echo
echo "[INFO] Test configuration Apache"



apache2ctl configtest



echo "[INFO] Redémarrage Apache"



systemctl restart apache2



###############################################################################
# Vérification
###############################################################################

if systemctl is-active --quiet apache2
then

    echo
    echo "[OK] Apache opérationnel"

else

    echo
    echo "[ERREUR] Apache ne fonctionne pas"

    exit 1

fi



echo
echo "==============================================================="
echo " VirtualHost Sentinelle installé"
echo " Accès : http://sentinelle.local"
echo "==============================================================="
