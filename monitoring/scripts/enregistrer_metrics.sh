#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/enregistrer_metrics.sh
###############################################################################


###############################################################################
# Chemin Git : monitoring/scripts/enregistrer_metrics.sh
###############################################################################

# 1. Capture des métriques système
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
SWAP=$(free | grep Swap | awk '{if ($2 > 0) print $3/$2 * 100.0; else print 0}')

# Valeurs par défaut si échec
CPU=${CPU:-0}
RAM=${RAM:-0}
DISK=${DISK:-0}
SWAP=${SWAP:-0}

# 2. Appel du script d'insertion BDD du même dossier
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/insertion_bdd.sh" "metrics" "${CPU}" "${RAM}" "${DISK}" "${SWAP}"
