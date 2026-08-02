#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement Backend Spring Boot Java 21 sur Port 8081
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Déploiement Backend Spring Boot (Port 8081)"
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

echo "[1/6] Nettoyage des processus sur le port 8081"
systemctl stop sentinelle-backend 2>/dev/null || true
fuser -k 8081/tcp 2>/dev/null || true
pkill -9 -f "sentinelle-backend" 2>/dev/null || true
sleep 1

echo "[2/6] Préparation du dossier /opt/sentinelle"
mkdir -p \
    "${INSTALL_DIR}/backend" \
    "${INSTALL_DIR}/config" \
    "${INSTALL_DIR}/bash" \
    "${INSTALL_DIR}/backups" \
    /var/log/sentinelle \
    /tmp/sentinelle

echo "[3/6] Compilation du projet Spring Boot"
cd "${SOURCE_BACKEND}"
mvn clean package -DskipTests

echo "[4/6] Installation du fichier JAR"
JAR_SOURCE=$(find target/ -name "*.jar" ! -name "*sources.jar" | head -n 1)
if [ -z "$JAR_SOURCE" ]; then
    echo "[ERREUR] Fichier JAR introuvable dans target/."
    exit 1
fi
cp "$JAR_SOURCE" "${INSTALL_DIR}/backend/sentinelle-backend-4.0.0.jar"

echo "[5/6] Copie des fichiers de configuration et scripts Bash"
cp -r "${SOURCE_CONFIG}/"* "${INSTALL_DIR}/config/" 2>/dev/null || true
cp -r "${SOURCE_BASH}/"* "${INSTALL_DIR}/bash/" 2>/dev/null || true
chmod -R +x "${INSTALL_DIR}/bash/"
chmod -R 755 "${INSTALL_DIR}"
chmod 755 /var/log/sentinelle

echo "[6/6] Configuration et démarrage du service Systemd sur le port 8081"
cat << EOF > /etc/systemd/system/sentinelle-backend.service
[Unit]
Description=Sentinelle V4 Backend Spring Boot Service
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/sentinelle/backend
ExecStart=${JAVA_BIN} -jar /opt/sentinelle/backend/sentinelle-backend-4.0.0.jar --server.port=8081 --spring.jpa.hibernate.ddl-auto=update --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration --spring.config.additional-location=optional:file:/opt/sentinelle/config/
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
