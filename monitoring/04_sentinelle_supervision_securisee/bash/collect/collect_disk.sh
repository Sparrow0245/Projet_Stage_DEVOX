#!/bin/bash
###############################################################################
# Sentinelle V4 - Collecte Espace Disque
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_disk.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
"INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage, network_rx_kb, network_tx_kb) \
VALUES (1, 0, 0, ${DISK_USAGE}, 0, 0, 0);"

if (( $(echo "${DISK_USAGE} > 85" | bc -l) )); then
    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO events (host_id, event_type, severity, message) \
    VALUES (1, 'DISK_HIGH', 'WARNING', 'Partition racine saturée à ${DISK_USAGE}%');"
fi
