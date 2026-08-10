#!/bin/bash

###############################################################################
# SENTINELLE V4
# Arrêt Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo "       ARRET DE SENTINELLE V4"
echo "==============================================================="

docker compose \
    -f compose.yml \
    -f compose.local.yml \
    down

echo
echo "[OK] Conteneurs arrêtés."
echo "[INFO] Les volumes persistants ne sont pas supprimés."
