#!/bin/bash

###############################################################################
# Sentinelle V4 - État Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo " ÉTAT DE SENTINELLE V4"
echo "==============================================================="

docker compose ps

echo
echo "==============================================================="
echo " UTILISATION DES RESSOURCES"
echo "==============================================================="

docker stats \
    --no-stream \
    sentinelle-collector \
    sentinelle-backend \
    sentinelle-web \
    sentinelle-db \
    2>/dev/null || true
