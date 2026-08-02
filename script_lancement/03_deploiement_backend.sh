#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Compilation & Déploiement du Backend Spring Boot Java 21 via Systemd
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

JAVA_BIN=$(which java || echo "/usr/bin/java")

echo "[1/6] Nettoyage des anciennes instances Java et services"
systemctl stop sentinelle-backend 2>/dev/null || true
fuser -k 8080/tcp 2>/dev/null || true
pkill -9 -f "sentinelle-backend" 2>/dev/null || true
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
chmod -R 755 "${INSTALL_DIR}"
chmod 755 /var/log/sentinelle

echo "[6/6] Configuration et démarrage du service Systemd backend"
cat << EOF > /etc/systemd/system/sentinelle-backend.service
[Unit]
Description=Sentinelle V4 Backend Spring Boot Service
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sentinelle/backend
ExecStart=${JAVA_BIN} -jar /opt/sentinelle/backend/sentinelle-backend-4.0.0.jar --server.port=8080 --spring.jpa.hibernate.ddl-auto=update --spring.config.additional-location=optional:file:/opt/sentinelle/config/
Restart=always
RestartSec=3
StandardOutput=file:/var/log/sentinelle/backend.log
StandardError=file:/var/log/sentinelle/backend.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sentinelle-backend.service
systemctl restart sentinelle-backend.service

echo "Attente de l'initialisation de l'API Spring Boot sur le port 8080..."
SUCCESS=0
for i in {1..25}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/metrics 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 401 ]; then
        echo "[OK] API Spring Boot fonctionnelle sur 8080 (Code HTTP ${HTTP_CODE})."
        SUCCESS=1
        break
    fi
    sleep 1
done

if [ $SUCCESS -eq 0 ]; then
    echo "[ERREUR CRITIQUE] Le backend n'a pas pu démarrer. Journal des erreurs :"
    echo "---------------------------------------------------------------"
    cat /var/log/sentinelle/backend.log 2>/dev/null || true
    echo "---------------------------------------------------------------"
    exit 1
fi

echo "==============================================================="
echo " Backend Spring Boot déployé et géré via Systemd"
echo "==============================================================="
