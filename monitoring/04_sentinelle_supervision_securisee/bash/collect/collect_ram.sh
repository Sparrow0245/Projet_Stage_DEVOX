#!/bin/bash
###############################################################################
# Sentinelle V4 - Collecte RAM & SWAP
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_ram.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"

RAM_USAGE=$(free -m | awk '/Mem:/ { printf("%.2f", $3/$2 * 100) }')
SWAP_USAGE=$(free -m | awk '/Swap:/ { if ($2>0) printf("%.2f", $3/$2 * 100); else print 0.0 }')

mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
"INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage) \
VALUES (1, 0, ${RAM_USAGE}, 0, ${SWAP_USAGE});"

if (( $(echo "${RAM_USAGE} > 85.0" | bc -l) )); then
    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO events (host_id, type, message) \
    VALUES (1, 'WARNING', 'Consommation RAM élevée : ${RAM_USAGE}%');"
fi
