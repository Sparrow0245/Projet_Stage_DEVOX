#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement du moteur Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Déploiement Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


SOURCE_SENTINELLE="${BASE_DIR}/monitoring/03_sentinelle_unifiee_multijails_corrigee"

SOURCE_CONFIG="${BASE_DIR}/monitoring/config"

SOURCE_SCRIPTS="${BASE_DIR}/monitoring/scripts"


INSTALL_DIR="/opt/sentinelle"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi



###############################################################################
# Vérification fichiers source
###############################################################################

echo "[INFO] Vérification des sources"



for DIR in \
    "${SOURCE_SENTINELLE}" \
    "${SOURCE_CONFIG}" \
    "${SOURCE_SCRIPTS}"
do

    if [[ ! -d "${DIR}" ]]; then

        echo "[ERREUR] Dossier introuvable : ${DIR}"
        exit 1

    fi

done



###############################################################################
# Création arborescence serveur
###############################################################################

echo
echo "[1/6] Création arborescence Sentinelle"



mkdir -p \
"${INSTALL_DIR}/config" \
"${INSTALL_DIR}/config/jails.d" \
"${INSTALL_DIR}/lib" \
"${INSTALL_DIR}/scripts" \
"${INSTALL_DIR}/data" \
"${INSTALL_DIR}/logs"



###############################################################################
# Copie moteur Sentinelle
###############################################################################

echo
echo "[2/6] Copie du moteur"



cp \
"${SOURCE_SENTINELLE}/sentinelle.sh" \
"${INSTALL_DIR}/"



cp \
"${SOURCE_SENTINELLE}/sentinelle-ctl.sh" \
"${INSTALL_DIR}/"



cp \
"${SOURCE_SENTINELLE}/lib/"*.sh \
"${INSTALL_DIR}/lib/"



###############################################################################
# Copie configuration
###############################################################################

echo
echo "[3/6] Copie configuration"



cp \
"${SOURCE_SENTINELLE}/config/"*.conf \
"${INSTALL_DIR}/config/"



cp \
"${SOURCE_CONFIG}/sentinelle.conf" \
"${INSTALL_DIR}/config/"



cp \
"${SOURCE_CONFIG}/database.conf" \
"${INSTALL_DIR}/config/"



###############################################################################
# Copie scripts monitoring
###############################################################################

echo
echo "[4/6] Copie scripts monitoring"



cp \
"${SOURCE_SCRIPTS}/"*.sh \
"${INSTALL_DIR}/scripts/"



###############################################################################
# Permissions
###############################################################################

echo
echo "[5/6] Application permissions"



chmod +x \
"${INSTALL_DIR}/sentinelle.sh"



chmod +x \
"${INSTALL_DIR}/sentinelle-ctl.sh"



chmod +x \
"${INSTALL_DIR}/lib/"*.sh



chmod +x \
"${INSTALL_DIR}/scripts/"*.sh



chown -R root:root "${INSTALL_DIR}"



###############################################################################
# Test rapide
###############################################################################

echo
echo "[6/6] Vérification installation"



if [[ -f "${INSTALL_DIR}/sentinelle.sh" ]]
then

    echo "[OK] Moteur Sentinelle installé"

else

    echo "[ERREUR] Installation incomplète"
    exit 1

fi



echo
echo "==============================================================="
echo " Sentinelle déployée dans ${INSTALL_DIR}"
echo "==============================================================="
