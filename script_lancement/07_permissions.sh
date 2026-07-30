#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 07 - Application des permissions et droits d'accès
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [07/09] Application des permissions de sécurité"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_ROOT="/var/www/html/sentinelle"
BASH_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/bash"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

# 1. Droits d'exécution sur les scripts Bash du collector
echo "[1/3] Attribution des droits d'exécution sur les scripts Bash"
if [[ -d "${BASH_DIR}" ]]; then
    chmod +x "${BASH_DIR}"/*.sh 2>/dev/null || true
    chmod +x "${BASH_DIR}"/collect/*.sh 2>/dev/null || true
    echo "[OK] Scripts Bash exécutables."
fi

# 2. Droits sur le répertoire Web Apache
echo "[2/3] Sécurisation du dossier Web (${WEB_ROOT})"
if [[ -d "${WEB_ROOT}" ]]; then
    chown -R www-data:www-data "${WEB_ROOT}"
    find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
    find "${WEB_ROOT}" -type f -exec chmod 644 {} \;
    echo "[OK] Permissions Web configurées (www-data)."
fi

# 3. Restriction du fichier de configuration MySQL
echo "[3/3] Restriction d'accès au fichier /etc/mysql/sentinelle.cnf"
if [[ -f "/etc/mysql/sentinelle.cnf" ]]; then
    chown root:root /etc/mysql/sentinelle.cnf
    chmod 600 /etc/mysql/sentinelle.cnf
    echo "[OK] Fichier de crédentiels MySQL protégé (600)."
fi

echo "==============================================================="
echo " Permissions appliquées avec succès !"
echo "==============================================================="
