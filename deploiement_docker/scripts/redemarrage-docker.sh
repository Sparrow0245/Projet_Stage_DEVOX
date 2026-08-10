#!/bin/bash

###############################################################################
# SENTINELLE V4
# Redémarrage Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo "       REDEMARRAGE DE SENTINELLE V4"
echo "==============================================================="

docker compose \
    -f compose.yml \
    -f compose.local.yml \
    restart

echo
echo "[OK] Sentinelle redémarrée."
