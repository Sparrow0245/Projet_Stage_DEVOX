#!/bin/bash

###############################################################################
# Sentinelle V4 - Entrypoint Collector Docker
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Sentinelle V4 - Collector Docker"
echo "==============================================================="

MYSQL_CONFIG_DIR="/etc/mysql"
MYSQL_CONFIG="${MYSQL_CONFIG_DIR}/sentinelle.cnf"

mkdir -p "${MYSQL_CONFIG_DIR}"

###############################################################################
# CONFIGURATION MYSQL
###############################################################################

cat > "${MYSQL_CONFIG}" <<EOF
[client]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
database=${DB_NAME}
EOF

chmod 600 "${MYSQL_CONFIG}"

export DB_CNF="${MYSQL_CONFIG}"

###############################################################################
# VARIABLES UTILISÉES PAR SENTINELLE
###############################################################################

export HOST_ID="${HOST_ID:-1}"

###############################################################################
# ATTENTE DE MYSQL
###############################################################################

echo "[INFO] Attente de la base de données ${DB_HOST}:${DB_PORT}..."

MAX_RETRIES=60
RETRY=0

until mysql \
    --defaults-extra-file="${MYSQL_CONFIG}" \
    --connect-timeout=3 \
    "${DB_NAME}" \
    -e "SELECT 1;" >/dev/null 2>&1
do
    RETRY=$((RETRY + 1))

    if [ "${RETRY}" -ge "${MAX_RETRIES}" ]; then
        echo "[ERREUR] Impossible de se connecter à la base de données."
        exit 1
    fi

    sleep 2
done

echo "[OK] Base de données accessible."

###############################################################################
# ENVIRONNEMENT HÔTE
###############################################################################

export HOST_ROOT="/host"

###############################################################################
# LANCEMENT DU COLLECTEUR
###############################################################################

cd /opt/sentinelle/bash

echo "[INFO] Démarrage de collector.sh..."

exec /bin/bash /opt/sentinelle/bash/collector.sh
