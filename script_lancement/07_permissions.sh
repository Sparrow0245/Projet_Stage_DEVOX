#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration des permissions Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Configuration des permissions Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

SENTINELLE_DIR="/opt/sentinelle"

WEB_DIR="/var/www/html/sentinelle"

LOG_DIR="/opt/sentinelle/logs"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then

    echo "[ERREUR] Ce script doit être exécuté avec sudo."

    exit 1

fi



###############################################################################
# Vérification dossiers
###############################################################################

echo "[1/5] Vérification dossiers"


for DIR in "${SENTINELLE_DIR}" "${WEB_DIR}"
do

    if [[ ! -d "${DIR}" ]]
    then

        echo "[ERREUR] Dossier absent : ${DIR}"

        exit 1

    fi

done



###############################################################################
# Permissions Sentinelle
###############################################################################

echo
echo "[2/5] Configuration permissions moteur"



mkdir -p "${LOG_DIR}"



chown -R root:root "${SENTINELLE_DIR}"



find "${SENTINELLE_DIR}" \
-type d \
-exec chmod 755 {} \;



find "${SENTINELLE_DIR}" \
-type f \
-exec chmod 644 {} \;



chmod +x "${SENTINELLE_DIR}/sentinelle.sh" || true

chmod +x "${SENTINELLE_DIR}/sentinelle-ctl.sh" || true



if [[ -d "${SENTINELLE_DIR}/scripts" ]]
then

    chmod +x "${SENTINELLE_DIR}/scripts/"*.sh || true

fi



if [[ -d "${SENTINELLE_DIR}/lib" ]]
then

    chmod +x "${SENTINELLE_DIR}/lib/"*.sh || true

fi



###############################################################################
# Permissions logs
###############################################################################

echo
echo "[3/5] Configuration logs"



chown -R root:adm "${LOG_DIR}"

chmod 750 "${LOG_DIR}"



###############################################################################
# Permissions Web
###############################################################################

echo
echo "[4/5] Configuration interface web"



chown -R www-data:www-data "${WEB_DIR}"



find "${WEB_DIR}" \
-type d \
-exec chmod 755 {} \;



find "${WEB_DIR}" \
-type f \
-exec chmod 644 {} \;



###############################################################################
# Protection fichiers sensibles
###############################################################################

echo
echo "[5/5] Protection configurations"



if [[ -d "${SENTINELLE_DIR}/config" ]]
then

    chmod 640 "${SENTINELLE_DIR}/config/"*.conf 2>/dev/null || true

fi



echo
echo "==============================================================="
echo " Permissions configurées"
echo "==============================================================="
