#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script principal d'installation
###############################################################################

set -euo pipefail

VERSION="1.0"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${BASE_DIR}/script_lancement"

LOG_FILE="/tmp/sentinelle_install.log"

clear

echo "==============================================================="
echo "             SENTINELLE MONITORING INSTALLER"
echo "==============================================================="
echo
echo "Version : ${VERSION}"
echo "Projet  : Projet_Stage_DEVOX"
echo

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

if [[ ! -d "${BASE_DIR}/monitoring" ]]; then
    echo "[ERREUR] Dossier monitoring introuvable."
    exit 1
fi

echo "[OK] Dépôt détecté."
echo

SCRIPTS=(
    "01_dependances.sh"
    "02_mysql.sh"
    "03_deploiement_sentinelle.sh"
    "04_deploiement_web.sh"
    "05_apache.sh"
    "06_systemd.sh"
    "07_permissions.sh"
    "08_tests.sh"
)

TOTAL=${#SCRIPTS[@]}
CURRENT=1

for SCRIPT in "${SCRIPTS[@]}"
do

    echo
    echo "---------------------------------------------------------------"
    echo "[${CURRENT}/${TOTAL}] ${SCRIPT}"
    echo "---------------------------------------------------------------"

    if [[ ! -f "${SCRIPT_DIR}/${SCRIPT}" ]]; then
        echo "[ERREUR] ${SCRIPT} est introuvable."
        exit 1
    fi

    chmod +x "${SCRIPT_DIR}/${SCRIPT}"

    bash "${SCRIPT_DIR}/${SCRIPT}" | tee -a "${LOG_FILE}"

    echo
    echo "[OK] ${SCRIPT} terminé."

    CURRENT=$((CURRENT+1))

done

echo
echo "==============================================================="
echo " Installation terminée avec succès."
echo "==============================================================="
echo

echo "Résumé :"

echo "  • Apache installé"

echo "  • PHP installé"

echo "  • MariaDB/MySQL installé"

echo "  • Base Sentinelle créée"

echo "  • Interface Web installée"

echo "  • Services systemd installés"

echo "  • Timers activés"

echo

echo "Journal :"

echo "  ${LOG_FILE}"

echo

echo "Fin de l'installation."
