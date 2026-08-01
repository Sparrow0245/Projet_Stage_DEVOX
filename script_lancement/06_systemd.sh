#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 06 - Configuration et activation des services Systemd
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [06/09] Configuration des services Systemd pour Sentinelle V4"
echo "==============================================================="

# Racines des dossiers relatives au dépôt Git
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MONITORING_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"
CONF_SRC="${MONITORING_DIR}/config/sentinelle.cnf.example"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Mise en place du fichier de configuration MariaDB
echo "[1/4] Vérification du fichier d'authentification /etc/mysql/sentinelle.cnf"
mkdir -p /etc/mysql
if [[ ! -f "/etc/mysql/sentinelle.cnf" ]]; then
    if [[ -f "${CONF_SRC}" ]]; then
        cp "${CONF_SRC}" /etc/mysql/sentinelle.cnf
    else
        cat <<EOF > /etc/mysql/sentinelle.cnf
[client]
user=sentinelle
password=sentinelle_password
host=localhost
database=sentinelle
EOF
    fi
    chmod 600 /etc/mysql/sentinelle.cnf
    chown root:root /etc/mysql/sentinelle.cnf
    echo "[OK] Fichier /etc/mysql/sentinelle.cnf configuré."
else
    echo "[OK] Fichier /etc/mysql/sentinelle.cnf déjà existant."
fi

# 2. Droits d'exécution sur le Collector et les sous-scripts Bash
echo "[2/4] Attribution des droits d'exécution sur les scripts Bash"
chmod +x "${MONITORING_DIR}/bash/collector.sh" 2>/dev/null || true
chmod +x "${MONITORING_DIR}/bash/collect/"*.sh 2>/dev/null || true
chmod +x "${MONITORING_DIR}/bash/utils/"*.sh 2>/dev/null || true

# 3. Génération et installation de l'unité Systemd de collecte
echo "[3/4] Installation du service Systemd pour la collecte temps réel"
cat <<EOF > /etc/systemd/system/sentinelle-monitor.service
[Unit]
Description=Sentinelle V4 Real-Time Metrics Collector Service
After=network.target mariadb.service

[Service]
Type=simple
ExecStart=/bin/bash ${MONITORING_DIR}/bash/collector.sh
WorkingDirectory=${MONITORING_DIR}/bash
Restart=always
RestartSec=2
User=root

[Install]
WantedBy=multi-user.target
EOF

# 4. Rechargement et démarrage des services Systemd
echo "[4/4] Activation et démarrage des services"
systemctl daemon-reload

if systemctl enable --now sentinelle-monitor.service 2>/dev/null; then
    echo "[OK] Service sentinelle-monitor activé et démarré."
fi

if systemctl is-active --quiet sentinelle-backend.service 2>/dev/null; then
    systemctl restart sentinelle-backend.service || true
    echo "[OK] Service sentinelle-backend redémarré."
fi

echo "==============================================================="
echo " Services Systemd configurés et démarrés avec succès !"
echo "==============================================================="
