#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Validation des permissions système
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Configuration des permissions système"
echo "==============================================================="

SENTINELLE_DIR="/opt/sentinelle"
WEB_DIR="/var/www/html/sentinelle"
LOG_DIR="/var/log/sentinelle"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/3] Sécurisation répertoire /opt/sentinelle"
chown -R root:root "${SENTINELLE_DIR}"
chmod -R 755 "${SENTINELLE_DIR}"
chmod -R +x "${SENTINELLE_DIR}/bash/"

echo
echo "[2/3] Sécurisation logs"
chown -R root:adm "${LOG_DIR}"
chmod 755 "${LOG_DIR}"

echo
echo "[3/3] Sécurisation dossier Web"
chown -R www-data:www-data "${WEB_DIR}"
chmod -R 755 "${WEB_DIR}"

echo
echo "==============================================================="
echo " Permissions appliquées"
echo "==============================================================="
