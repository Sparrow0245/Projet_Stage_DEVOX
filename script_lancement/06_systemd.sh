#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Installation des services et timers systemd V4 (Spring Boot sur port 8081)
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Installation services & timers systemd V4"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"

SOURCE_SYSTEMD="${APP_DIR}/systemd"
SYSTEMD_DIR="/etc/systemd/system"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "[1/4] Copie des fichiers Services & Timers"
cp "${SOURCE_SYSTEMD}/services/"*.service "${SYSTEMD_DIR}/"
cp "${SOURCE_SYSTEMD}/timers/"*.timer "${SYSTEMD_DIR}/"

# Forcer le port 8081 pour Spring Boot pour libérer le port 8080 pour Apache
sed -i 's|sentinelle-backend-4.0.0.jar|sentinelle-backend-4.0.0.jar --server.port=8081|g' "${SYSTEMD_DIR}/sentinelle-backend.service"

echo
echo "[2/4] Rechargement de systemd"
systemctl daemon-reload

echo
echo "[3/4] Activation des services au démarrage"
systemctl enable sentinelle-backend.service
systemctl enable sentinelle-monitor.timer

echo
echo "[4/4] Démarrage immédiat des services"
systemctl restart sentinelle-backend.service
systemctl restart sentinelle-monitor.timer

echo
echo "==============================================================="
echo " Services Backend (port 8081) et Timers activés"
echo "==============================================================="
