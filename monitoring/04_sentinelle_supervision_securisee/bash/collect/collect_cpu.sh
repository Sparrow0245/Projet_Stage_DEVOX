#!/bin/bash
###############################################################################
# Sentinelle V4 - Collecte de l'utilisation CPU
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_cpu.sh
###############################################################################
set -euo pipefail

# Définition du fichier de conf MySQL si absent de l'environnement
DB_CNF="${DB_CNF:-/etc/mysql/sentinelle.cnf}"

# Calcul du % d'utilisation CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Contrôle du seuil d'alerte (Ex: > 80%)
if (( $(echo "${CPU_USAGE} > 80.0" | bc -l) )); then
    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO events (host_id, type, message) VALUES (1, 'WARNING', 'Consommation CPU élevée : ${CPU_USAGE}%');" 2>/dev/null
fi

# Retour de la valeur pour orchestrateur (collector.sh)
echo "${CPU_USAGE}"
