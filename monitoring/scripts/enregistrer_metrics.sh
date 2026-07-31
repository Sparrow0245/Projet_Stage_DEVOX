#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/enregistrer_metrics.sh
###############################################################################

# 1. Capture des métriques
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
SWAP=$(free | grep Swap | awk '{if ($2 > 0) print $3/$2 * 100.0; else print 0}')

# Valeurs de sécurité si une commande échoue
CPU=${CPU:-0}
RAM=${RAM:-0}
DISK=${DISK:-0}
SWAP=${SWAP:-0}

# 2. Transmission au script d'insertion BDD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/insertion_bdd.sh" "metrics" "${CPU}" "${RAM}" "${DISK}" "${SWAP}"
