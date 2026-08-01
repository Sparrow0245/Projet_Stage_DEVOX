#!/bin/bash

###############################################################################
# Projet Stage DEVOX - Script Maître de Déploiement
# Exécute la chaîne complète des scripts 01 à 08
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==============================================================="
echo "   DÉPLOIEMENT AUTOMATISÉ - PLATAFORME SENTINELLE V4          "
echo "==============================================================="

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Le script de lancement doit être exécuté avec sudo."
    exit 1
fi

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

for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="${SCRIPT_DIR}/${script}"
    if [[ -f "${SCRIPT_PATH}" ]]; then
        echo -e "\n>>> Exécution de ${script}..."
        bash "${SCRIPT_PATH}"
    else
        echo -e "\n[ERREUR] Script manquant : ${script}"
        exit 1
    fi
done

echo -e "\n==============================================================="
echo " DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !"
echo " API Backend (Spring Boot) : http://localhost:8080/api/metrics"
echo " Interface Frontend        : http://localhost/"
echo " Service Collector Systemd : sentinelle-monitor.service"
echo "==============================================================="
