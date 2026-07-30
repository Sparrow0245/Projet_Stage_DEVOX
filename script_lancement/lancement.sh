#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script principal d'orchestration et d'installation Sentinelle V4
###############################################################################

set -euo pipefail

VERSION="4.0.0"
LOG_FILE="/tmp/sentinelle_install.log"

# Initialisation/vidage du fichier de log
> "${LOG_FILE}"

clear

echo "==============================================================="
echo "             SENTINELLE MONITORING V4 INSTALLER"
echo "==============================================================="
echo
echo "Version : ${VERSION}"
echo "Projet  : Projet_Stage_DEVOX"
echo

# 1. Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 2. Détection dynamique des répertoires (Racine ou script_lancement)
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${CURRENT_DIR}/01_dependances.sh" ]]; then
    SCRIPT_DIR="${CURRENT_DIR}"
    BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
elif [[ -f "${CURRENT_DIR}/script_lancement/01_dependances.sh" ]]; then
    BASE_DIR="${CURRENT_DIR}"
    SCRIPT_DIR="${BASE_DIR}/script_lancement"
else
    echo "[ERREUR] Dossier script_lancement introuvable depuis $(pwd)."
    exit 1
fi

# 3. Validation du dossier de l'application
APP_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"
if [[ ! -d "${APP_DIR}" ]]; then
    echo "[ERREUR] Dossier d'application V4 introuvable : ${APP_DIR}"
    exit 1
fi

echo "[OK] Arborescence V4 validée."
echo "[INFO] Journal d'installation : ${LOG_FILE}"
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

for SCRIPT in "${SCRIPTS[@]}"; do
    echo
    echo "---------------------------------------------------------------"
    echo "[${CURRENT}/${TOTAL}] Exécution de ${SCRIPT}"
    echo "---------------------------------------------------------------"

    SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT}"

    if [[ ! -f "${SCRIPT_PATH}" ]]; then
        echo "[ERREUR] Script introuvable : ${SCRIPT_PATH}"
        exit 1
    fi

    chmod +x "${SCRIPT_PATH}"

    # Exécution avec journalisation et arrêt immédiat en cas d'échec
    if ! "${SCRIPT_PATH}" 2>&1 | tee -a "${LOG_FILE}"; then
        echo
        echo "[ÉCHEC] Erreur détectée lors de l'exécution de ${SCRIPT}."
        echo "Consultez ${LOG_FILE} pour plus de détails."
        exit 1
    fi

    echo
    echo "[OK] ${SCRIPT} terminé avec succès."
    CURRENT=$((CURRENT+1))
done

echo
echo "==============================================================="
echo " Installation Sentinelle V4 terminée avec succès !"
echo "==============================================================="
echo
echo "Résumé du déploiement :"
echo "  • Dépendances système (Java 21, PHP, Apache, MariaDB) installées"
echo "  • Base de données MySQL/MariaDB configurée & schéma V4 importé"
echo "  • Backend Spring Boot compilé et configuré sur le port 8081"
echo "  • Frontend Web PHP déployé dans /var/www/html/sentinelle"
echo "  • Reverse Proxy Apache configuré (Ports 80 & 8080 -> Backend 8081)"
echo "  • Services Systemd & Timers de collecte activés"
echo "  • Suite de tests validée à 100%"
echo
echo "URL d'accès :"
echo "  http://localhost:8080"
echo
echo "Journal complet d'installation : ${LOG_FILE}"
echo "==============================================================="
