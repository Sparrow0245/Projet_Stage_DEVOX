#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Compilation & Déploiement du Backend Spring Boot Java 21
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Déploiement Backend Spring Boot"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"

SOURCE_BACKEND="${APP_DIR}/backend"
SOURCE_CONFIG="${APP_DIR}/config"
SOURCE_BASH="${APP_DIR}/bash"

INSTALL_DIR="/opt/sentinelle"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/5] Création de l'arborescence /opt/sentinelle"
mkdir -p \
    "${INSTALL_DIR}/backend" \
    "${INSTALL_DIR}/config" \
    "${INSTALL_DIR}/bash" \
    "${INSTALL_DIR}/backups" \
    /var/log/sentinelle \
    /tmp/sentinelle

echo
echo "[2/5] Compilation Maven du Backend"
cd "${SOURCE_BACKEND}"
mvn clean package -DskipTests

echo
echo "[3/5] Déploiement de l'exécutable JAR"
cp target/sentinelle-backend-*.jar "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar"

echo
echo "[4/5] Copie des configurations et scripts Bash"
cp -r "${SOURCE_CONFIG}/"* "${INSTALL_DIR}/config/"
cp -r "${SOURCE_BASH}/"* "${INSTALL_DIR}/bash/"

echo
echo "[5/5] Application des droits d'exécution"
chmod -R +x "${INSTALL_DIR}/bash/"
chmod 755 /var/log/sentinelle

echo
echo "==============================================================="
echo " Backend Spring Boot & Scripts déployés dans ${INSTALL_DIR}"
echo "==============================================================="
