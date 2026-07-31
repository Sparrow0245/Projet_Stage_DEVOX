#!/bin/bash

###############################################################################
# Sentinelle V4 - Orchestrateur Principal de Collecte
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collector.sh
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECT_DIR="${SCRIPT_DIR}/collect"

if [[ ! -d "${COLLECT_DIR}" ]]; then
    echo "[ERREUR] Le dossier de collecte ${COLLECT_DIR} est introuvable." >&2
    exit 1
fi

# Exécution de chaque script de collecte individuel
for script in "${COLLECT_DIR}"/collect_*.sh; do
    if [[ -x "${script}" ]]; then
        bash "${script}" || echo "[ATTENTION] Erreur lors de l'exécution de ${script}" >&2
    fi
done
