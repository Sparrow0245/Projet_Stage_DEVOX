#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Sentinelle V4
#
# Déploiement Docker automatisé
#
# Usage :
#   ./lancement-docker.sh
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${DOCKER_DIR}"

echo "==============================================================="
echo "       DÉPLOIEMENT DOCKER - SENTINELLE V4"
echo "==============================================================="

###############################################################################
# VERIFICATION DOCKER
###############################################################################

if ! command -v docker >/dev/null 2>&1; then

    echo "[ERREUR] Docker n'est pas installé."

    echo
    echo "Installe Docker sur le serveur avant de lancer Sentinelle."

    exit 1
fi

if ! docker info >/dev/null 2>&1; then

    echo "[ERREUR] Docker n'est pas accessible."

    echo "Vérifie que le service Docker est démarré et que"
    echo "l'utilisateur courant dispose des droits nécessaires."

    exit 1
fi

###############################################################################
# VERIFICATION COMPOSE
###############################################################################

if ! docker compose version >/dev/null 2>&1; then

    echo "[ERREUR] Docker Compose n'est pas disponible."

    exit 1
fi

###############################################################################
# CONFIGURATION
###############################################################################

if [[ ! -f ".env" ]]; then

    echo "[INFO] Aucun fichier .env trouvé."

    if [[ ! -f ".env.example" ]]; then

        echo "[ERREUR] .env.example est absent."

        exit 1
    fi

    cp ".env.example" ".env"

    echo
    echo "[ATTENTION]"
    echo "Le fichier .env vient d'être créé."
    echo "Modifie les mots de passe et secrets avant de continuer."
    echo

    exit 1
fi

source ".env"

###############################################################################
# VERIFICATION VARIABLES OBLIGATOIRES
###############################################################################

if [[ "${DB_MODE:-}" != "local" && "${DB_MODE:-}" != "external" ]]; then

    echo "[ERREUR] DB_MODE doit être 'local' ou 'external'."

    exit 1
fi

if [[ -z "${DB_PASSWORD:-}" ]]; then

    echo "[ERREUR] DB_PASSWORD n'est pas configuré."

    exit 1
fi

if [[ -z "${JWT_SECRET:-}" ]]; then

    echo "[ERREUR] JWT_SECRET n'est pas configuré."

    exit 1
fi

###############################################################################
# CONFIGURATION BASE DE DONNÉES
###############################################################################

if [[ "${DB_MODE}" == "local" ]]; then

    echo "[INFO] Mode BDD : MariaDB Docker"

    export DB_HOST="sentinelle-db"

    docker compose \
        --env-file .env \
        build

    docker compose \
        --env-file .env \
        up -d

else

    echo "[INFO] Mode BDD : MySQL/MariaDB externe"

    if [[ -z "${EXTERNAL_DB_HOST:-}" ]]; then

        echo "[ERREUR] EXTERNAL_DB_HOST n'est pas configuré."

        exit 1
    fi

    export DB_HOST="${EXTERNAL_DB_HOST}"
    export DB_PORT="${EXTERNAL_DB_PORT:-3306}"
    export DB_NAME="${EXTERNAL_DB_NAME:-sentinelle}"
    export DB_USER="${EXTERNAL_DB_USER:-sentinelle}"
    export DB_PASSWORD="${EXTERNAL_DB_PASSWORD}"

    if [[ -z "${DB_PASSWORD}" ]]; then

        echo "[ERREUR] EXTERNAL_DB_PASSWORD n'est pas configuré."

        exit 1
    fi

    docker compose \
        --env-file .env \
        build \
        sentinelle-collector \
        sentinelle-backend \
        sentinelle-web

    docker compose \
        --env-file .env \
        up -d \
        sentinelle-collector \
        sentinelle-backend \
        sentinelle-web
fi

###############################################################################
# VERIFICATION
###############################################################################

echo
echo "==============================================================="
echo " Vérification des conteneurs"
echo "==============================================================="

docker compose ps

echo
echo "==============================================================="
echo " SENTINELLE V4 - DÉPLOIEMENT TERMINÉ"
echo "==============================================================="

echo
echo "Interface Web :"
echo "    http://localhost:${WEB_PORT:-8080}"

echo
echo "Backend :"
echo "    http://localhost:${APP_PORT:-8080}"

echo
echo "Pour afficher les logs :"
echo "    ./scripts/logs-docker.sh"

echo
echo "Pour afficher l'état :"
echo "    ./scripts/statut-docker.sh"

echo
echo "==============================================================="
