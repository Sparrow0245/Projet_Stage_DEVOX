#!/bin/bash

###############################################################################
# Sentinelle V4 - Redémarrage Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo " REDÉMARRAGE DE SENTINELLE V4"
echo "==============================================================="

docker compose restart

echo
echo "[OK] Sentinelle V4 redémarrée."
