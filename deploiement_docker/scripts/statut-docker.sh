#!/bin/bash

###############################################################################
# SENTINELLE V4
# Etat Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo "       ETAT DE SENTINELLE V4"
echo "==============================================================="

docker compose \
    -f compose.yml \
    -f compose.local.yml \
    ps

echo
echo "==============================================================="
echo "       UTILISATION DES RESSOURCES"
echo "==============================================================="

docker stats \
    --no-stream \
    sentinelle-collector \
    sentinelle-web \
    sentinelle-db \
    2>/dev/null || true
