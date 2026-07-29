#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script principal d'installation Sentinelle V4
###############################################################################

set -euo pipefail

VERSION="4.0"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="${BASE_DIR}/script_lancement"

LOG_FILE="/tmp/sentinelle_install.log"

clear

echo "==============================================================="
echo "             SENTINELLE MONITORING V4 INSTALLER"
echo "==============================================================="
echo
echo "Version : ${VERSION}"
echo "Projet  : Projet_Stage_DEVOX"
echo

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

if [[ ! -d "${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee" ]]; then
    echo "[ERREUR] Dossier d'application V4 introuvable dans monitoring."
    exit 1
fi

echo "[OK] Dépôt V4 détecté."
echo

SCRIPTS=(
    "01_dependances.sh"
    "02_mysql.sh"
    "03_deploiement_backend.sh"
    "04_deploiement_frontend.sh"
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
echo " Installation V4 terminée avec succès."
echo "==============================================================="
echo
echo "Résumé :"
echo "  • Outils système & Java 21 / Maven / Node.js installés"
echo "  • MariaDB/MySQL V4 configuré"
echo "  • Backend Spring Boot compilé & déployé"
echo "  • Frontend Vue.js compilé & déployé"
echo "  • Reverse Proxy Apache configuré avec SSL"
echo "  • Services & Timers systemd actifs"
echo
echo "Journal : ${LOG_FILE}"
echo
