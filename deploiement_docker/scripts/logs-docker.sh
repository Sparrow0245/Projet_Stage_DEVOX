#!/bin/bash

###############################################################################
# Sentinelle V4 - Logs Docker
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

SERVICE="${1:-}"

if [[ -n "${SERVICE}" ]]; then

    docker compose logs -f "${SERVICE}"

else

    docker compose logs -f --tail=100

fi
