#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Sentinelle V4
#
# Déploiement Docker automatisé
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo "       DEPLOIEMENT DOCKER - SENTINELLE V4"
echo "==============================================================="

###############################################################################
# VERIFICATION DOCKER
###############################################################################

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERREUR] Docker n'est pas installé."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "[ERREUR] Docker n'est pas accessible."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "[ERREUR] Docker Compose n'est pas disponible."
    exit 1
fi

echo "[OK] Docker disponible."

###############################################################################
# CREATION .ENV
###############################################################################

if [ ! -f .env ]; then

    echo "[INFO] Création du fichier .env..."

    cp .env.example .env

    echo
    echo "Le fichier .env a été créé."
    echo "Configure-le avant de relancer le script."
    echo

    exit 1
fi

###############################################################################
# CHARGEMENT CONFIGURATION
###############################################################################

set -a
source .env
set +a

DB_MODE="${DB_MODE:-local}"

###############################################################################
# VERIFICATION MODE
###############################################################################

if [ "${DB_MODE}" != "local" ] &&
   [ "${DB_MODE}" != "external" ]; then

    echo "[ERREUR] DB_MODE doit être 'local' ou 'external'."

    exit 1
fi

###############################################################################
# CONFIGURATION BDD LOCALE
###############################################################################

if [ "${DB_MODE}" = "local" ]; then

    echo
    echo "[INFO] Mode BDD : MariaDB Docker"

    if [ -z "${MYSQL_ROOT_PASSWORD:-}" ] ||
       [ "${MYSQL_ROOT_PASSWORD}" = "CHANGE_ME_ROOT_PASSWORD" ]; then

        echo "[ERREUR] MYSQL_ROOT_PASSWORD doit être défini dans .env."
        exit 1
    fi

    if [ -z "${DB_PASSWORD:-}" ] ||
       [ "${DB_PASSWORD}" = "CHANGE_ME" ]; then

        echo "[ERREUR] DB_PASSWORD doit être défini dans .env."
        exit 1
    fi

    export DB_HOST="sentinelle-db"

    docker compose \
        -f compose.yml \
        -f compose.local.yml \
        build

    docker compose \
        -f compose.yml \
        -f compose.local.yml \
        up -d

###############################################################################
# CONFIGURATION BDD EXTERNE
###############################################################################

else

    echo
    echo "[INFO] Mode BDD : MySQL/MariaDB externe"

    if [ -z "${EXTERNAL_DB_HOST:-}" ]; then
        echo "[ERREUR] EXTERNAL_DB_HOST est obligatoire."
        exit 1
    fi

    if [ -z "${EXTERNAL_DB_PASSWORD:-}" ]; then
        echo "[ERREUR] EXTERNAL_DB_PASSWORD est obligatoire."
        exit 1
    fi

    export DB_HOST="${EXTERNAL_DB_HOST}"
    export DB_PORT="${EXTERNAL_DB_PORT:-3306}"
    export DB_NAME="${EXTERNAL_DB_NAME:-sentinelle}"
    export DB_USER="${EXTERNAL_DB_USER:-sentinelle}"
    export DB_PASSWORD="${EXTERNAL_DB_PASSWORD}"

    docker compose \
        -f compose.yml \
        build

    docker compose \
        -f compose.yml \
        up -d

fi

###############################################################################
# ETAT
###############################################################################

echo
echo "==============================================================="
echo "       ETAT DES CONTENEURS"
echo "==============================================================="

if [ "${DB_MODE}" = "local" ]; then

    docker compose \
        -f compose.yml \
        -f compose.local.yml \
        ps

else

    docker compose \
        -f compose.yml \
        ps

fi

###############################################################################
# FIN
###############################################################################

echo
echo "==============================================================="
echo "       SENTINELLE V4 DEPLOYEE"
echo "==============================================================="

echo
echo "Interface Web :"
echo "    http://localhost:${WEB_PORT:-8080}"

echo
echo "Logs :"
echo "    ./scripts/logs-docker.sh"

echo
echo "Etat :"
echo "    ./scripts/statut-docker.sh"

echo
echo "==============================================================="
