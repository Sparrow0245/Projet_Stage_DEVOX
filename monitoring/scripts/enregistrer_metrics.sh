#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/enregistrer_metrics.sh
###############################################################################

# Forcer la locale C (Anglais/ASCII) pour éviter les problèmes de traduction (ex: Mém. au lieu de Mem)
export LC_ALL=C
export LANG=C

# Configuration BDD
DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

# Calcul CPU (%)
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d',' -f1 | cut -d'.' -f1)
if [ -z "$CPU_IDLE" ]; then
    CPU_USAGE=0
else
    CPU_USAGE=$((100 - CPU_IDLE))
fi

# Calcul RAM (%)
RAM_USAGE=$(free | awk '/Mem:/ {if ($2 > 0) printf("%.2f", $3/$2 * 100); else print "0"}')

# Calcul Disque (%)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Calcul SWAP (%)
SWAP_USAGE=$(free | awk '/Swap:/ {if ($2 > 0) printf("%.2f", $3/$2 * 100); else print "0"}')

# S'assurer que les valeurs ne sont pas vides
CPU_USAGE=${CPU_USAGE:-0}
RAM_USAGE=${RAM_USAGE:-0}
DISK_USAGE=${DISK_USAGE:-0}
SWAP_USAGE=${SWAP_USAGE:-0}

# Insertion MariaDB avec capture d'erreur
mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES ($CPU_USAGE, $RAM_USAGE, $DISK_USAGE, $SWAP_USAGE);" 2>> /tmp/sentinelle_metrics.log
