#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Compilation & Déploiement du Backend Spring Boot Java 21
###############################################################################

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
echo "[1/6] Création de l'arborescence /opt/sentinelle"
mkdir -p \
    "${INSTALL_DIR}/backend" \
    "${INSTALL_DIR}/config" \
    "${INSTALL_DIR}/bash" \
    "${INSTALL_DIR}/backups" \
    /var/log/sentinelle \
    /tmp/sentinelle

echo
echo "[2/6] Arrêt des anciennes instances du backend"
pkill -f "sentinelle-backend" 2>/dev/null || true
sleep 1

echo
echo "[3/6] Compilation Maven du Backend"
cd "${SOURCE_BACKEND}"
mvn clean package -DskipTests

echo
echo "[4/6] Déploiement de l'exécutable JAR"
JAR_SOURCE=$(find target/ -name "*.jar" ! -name "*sources.jar" | head -n 1)
if [ -z "$JAR_SOURCE" ]; then
    echo "[ERREUR] Aucun fichier JAR généré dans target/."
    exit 1
fi
cp "$JAR_SOURCE" "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar"

echo
echo "[5/6] Copie des configurations et scripts Bash"
cp -r "${SOURCE_CONFIG}/"* "${INSTALL_DIR}/config/"
cp -r "${SOURCE_BASH}/"* "${INSTALL_DIR}/bash/"
chmod -R +x "${INSTALL_DIR}/bash/"
chmod 755 /var/log/sentinelle

echo
echo "[6/6] Démarrage du service Backend Spring Boot"
nohup java -jar "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar" > /var/log/sentinelle/backend.log 2>&1 &

# Attente active du port 8080
echo "Attente de l'initialisation du backend sur le port 8080..."
for i in {1..15}; do
    if curl -s http://localhost:8080/api/metrics >/dev/null 2>&1; then
        echo "[OK] Spring Boot actif sur le port 8080 !"
        break
    fi
    sleep 1
done

echo "==============================================================="
echo " Backend Spring Boot & Scripts déployés et démarrés dans ${INSTALL_DIR}"
echo "==============================================================="
