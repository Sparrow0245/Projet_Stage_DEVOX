#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/enregistrer_metrics.sh
###############################################################################

#!/bin/bash

# Configuration BDD
DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

# Calcul de l'utilisation CPU (%)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Calcul de l'utilisation RAM (%)
RAM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

# Calcul de l'utilisation Disque (%)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Calcul du SWAP (%)
SWAP_TOTAL=$(free | grep Swap | awk '{print $2}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_USAGE=$(free | grep Swap | awk '{print $3/$2 * 100.0}')
else
    SWAP_USAGE=0
fi

# Insertion dans MariaDB
mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
"INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage) VALUES ($CPU_USAGE, $RAM_USAGE, $DISK_USAGE, $SWAP_USAGE);"
