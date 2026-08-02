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

echo "[1/6] Nettoyage des anciennes instances Java"
pkill -f "sentinelle-backend" 2>/dev/null || true
pkill -f "java -jar" 2>/dev/null || true
sleep 1

echo "[2/6] Création de l'arborescence /opt/sentinelle"
mkdir -p \
    "${INSTALL_DIR}/backend" \
    "${INSTALL_DIR}/config" \
    "${INSTALL_DIR}/bash" \
    "${INSTALL_DIR}/backups" \
    /var/log/sentinelle \
    /tmp/sentinelle

echo "[3/6] Compilation Maven du Backend"
cd "${SOURCE_BACKEND}"
mvn clean package -DskipTests

echo "[4/6] Déploiement de l'exécutable JAR"
JAR_SOURCE=$(find target/ -name "*.jar" ! -name "*sources.jar" | head -n 1)
if [ -z "$JAR_SOURCE" ]; then
    echo "[ERREUR] Aucun fichier JAR généré dans target/."
    exit 1
fi
cp "$JAR_SOURCE" "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar"

echo "[5/6] Copie des configurations et scripts Bash"
cp -r "${SOURCE_CONFIG}/"* "${INSTALL_DIR}/config/" 2>/dev/null || true
cp -r "${SOURCE_BASH}/"* "${INSTALL_DIR}/bash/" 2>/dev/null || true
chmod -R +x "${INSTALL_DIR}/bash/"
chmod 755 /var/log/sentinelle

echo "[6/6] Démarrage du backend Spring Boot en arrière-plan"
cd "${INSTALL_DIR}/backend"
nohup java -jar "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar" --spring.config.location=file:${INSTALL_DIR}/config/ > /var/log/sentinelle/backend.log 2>&1 &

sleep 3

echo "==============================================================="
echo " Backend Spring Boot & Scripts déployés"
echo "==============================================================="
