#!/bin/bash
###############################################################################
# Sentinelle V4 - Script maître d'exécution de la collecte
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collector.sh
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/collect" && pwd)"

for script in "${SCRIPT_DIR}"/collect_*.sh; do
    if [[ -x "${script}" ]]; then
        "${script}"
    else
        bash "${script}"
    fi
done
