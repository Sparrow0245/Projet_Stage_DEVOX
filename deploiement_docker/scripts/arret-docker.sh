#!/bin/bash

###############################################################################
# Sentinelle V4 - Arrêt Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo " ARRÊT DE SENTINELLE V4"
echo "==============================================================="

docker compose down

echo
echo "[OK] Les conteneurs Sentinelle sont arrêtés."
echo "[INFO] Les volumes persistants ne sont pas supprimés."
