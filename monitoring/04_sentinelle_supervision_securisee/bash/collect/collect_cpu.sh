#!/bin/bash
###############################################################################
# Sentinelle V4 - Collecte de l'utilisation CPU
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_cpu.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"

# Calcul du % d'utilisation CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Insertion de la métrique
mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
"INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage) \
VALUES (1, ${CPU_USAGE}, 0, 0, 0);"

# Contrôle du seuil d'alerte (Ex: > 80%)
if (( $(echo "${CPU_USAGE} > 80.0" | bc -l) )); then
    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO events (host_id, type, message) \
    VALUES (1, 'WARNING', 'Consommation CPU élevée : ${CPU_USAGE}%');"
fi
