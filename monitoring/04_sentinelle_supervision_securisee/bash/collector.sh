#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script Maître de Collecte - Sentinelle V4
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECT_DIR="${SCRIPT_DIR}/collect"
CONF_FILE="/etc/mysql/sentinelle.cnf"

# Vérification du fichier de configuration MySQL
if [[ ! -f "${CONF_FILE}" ]]; then
    echo "[ERREUR] Fichier de configuration introuvable : ${CONF_FILE}" >&2
    exit 1
fi

# Exécution des modules de collecte
CPU_USAGE=$("${COLLECT_DIR}/collect_cpu.sh" 2>/dev/null || echo "0")
RAM_USAGE=$("${COLLECT_DIR}/collect_ram.sh" 2>/dev/null || echo "0")
DISK_USAGE=$("${COLLECT_DIR}/collect_disk.sh" 2>/dev/null || echo "0")
SERVICES_STATUS=$("${COLLECT_DIR}/collect_services.sh" 2>/dev/null || echo "{}")

# Insertion dans la base de données
QUERY="INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, services_status, created_at) VALUES ('${CPU_USAGE}', '${RAM_USAGE}', '${DISK_USAGE}', '${SERVICES_STATUS}', NOW());"

mysql --defaults-extra-file="${CONF_FILE}" sentinelle -e "${QUERY}" 2>/dev/null
