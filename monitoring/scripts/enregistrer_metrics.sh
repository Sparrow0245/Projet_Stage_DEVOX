#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/enregistrer_metrics.sh
###############################################################################

# Force la locale C pour éviter que free/top n'utilisent des virgules au lieu des points
export LC_ALL=C

DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

# 1. Calcul du CPU (%)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "0")
CPU_USAGE=$(echo "${CPU_USAGE}" | tr ',' '.' | awk '{printf "%.2f", $1}')

# 2. Calcul de la RAM (%)
RAM_USAGE=$(free -m | awk '/Mem:/ {if ($2>0) printf "%.2f", $3/$2*100; else print 0}')
RAM_USAGE=$(echo "${RAM_USAGE}" | tr ',' '.')

# 3. Calcul du Disque (%)
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%' | tr ',' '.')

# 4. Calcul du SWAP (%)
SWAP_USAGE=$(free -m | awk '/Swap:/ {if ($2>0) printf "%.2f", $3/$2*100; else print 0}')
SWAP_USAGE=$(echo "${SWAP_USAGE}" | tr ',' '.')

# Sécurisation des variables si vides
CPU_USAGE=${CPU_USAGE:-0}
RAM_USAGE=${RAM_USAGE:-0}
DISK_USAGE=${DISK_USAGE:-0}
SWAP_USAGE=${SWAP_USAGE:-0}

# Insertion en BDD (tentative avec l'utilisateur sentinelle, puis fallback root)
mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});" 2>/dev/null \
|| mariadb -u root "${DB_NAME}" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES (${CPU_USAGE}, ${RAM_USAGE}, ${DISK_USAGE}, ${SWAP_USAGE});"
