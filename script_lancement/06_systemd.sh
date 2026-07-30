#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 06 - Configuration et activation des services Systemd
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [06/09] Configuration des services Systemd pour Sentinelle V4"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_SRC="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/config/sentinelle.cnf.example"
SERVICES_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/systemd/services"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Mise en place des identifiants MySQL pour le collector
echo "[1/3] Configuration du fichier d'authentification /etc/mysql/sentinelle.cnf"
if [[ -f "${CONF_SRC}" ]]; then
    cp "${CONF_SRC}" /etc/mysql/sentinelle.cnf
    chmod 600 /etc/mysql/sentinelle.cnf
    chown root:root /etc/mysql/sentinelle.cnf
    echo "[OK] Fichier /etc/mysql/sentinelle.cnf configuré."
else
    echo "[ATTENTION] Modèle de configuration introuvable : ${CONF_SRC}"
fi

# 2. Copie des unités de services Systemd
echo "[2/3] Copie des fichiers .service depuis systemd/services/"
if [[ -d "${SERVICES_DIR}" ]]; then
    cp "${SERVICES_DIR}/sentinelle-backend.service" /etc/systemd/system/ 2>/dev/null || true
    cp "${SERVICES_DIR}/sentinelle-monitor.service" /etc/systemd/system/ 2>/dev/null || true
    echo "[OK] Services copiés dans /etc/systemd/system/"
else
    echo "[ERREUR] Dossier introuvable : ${SERVICES_DIR}"
    exit 1
fi

# 3. Rechargement et activation des services
echo "[3/3] Activation et démarrage des services Systemd"
systemctl daemon-reload

if systemctl enable --now sentinelle-backend.service 2>/dev/null; then
    echo "[OK] Service sentinelle-backend activé."
fi

if systemctl enable --now sentinelle-monitor.service 2>/dev/null; then
    echo "[OK] Service sentinelle-monitor activé."
fi

echo "==============================================================="
echo " Service Systemd configuré avec succès !"
echo "==============================================================="
