#!/bin/bash

###############################################################################
# SENTINELLE V4
# Entrypoint Collector Docker
###############################################################################

set -euo pipefail

echo "==============================================================="
echo "       SENTINELLE V4 - COLLECTOR DOCKER"
echo "==============================================================="

###############################################################################
# CONFIGURATION MYSQL
###############################################################################

mkdir -p /etc/mysql

cat > /etc/mysql/sentinelle.cnf <<EOF
[client]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
database=${DB_NAME}
EOF

chmod 600 /etc/mysql/sentinelle.cnf

export DB_CNF="/etc/mysql/sentinelle.cnf"

###############################################################################
# VARIABLES SENTINELLE
###############################################################################

export HOST_ID="${HOST_ID:-1}"

###############################################################################
# ATTENTE BDD
###############################################################################

echo "[INFO] Attente de MySQL/MariaDB..."

MAX_RETRIES=60
RETRY=0

until mysql \
    --defaults-extra-file=/etc/mysql/sentinelle.cnf \
    --connect-timeout=3 \
    "${DB_NAME}" \
    -e "SELECT 1;" >/dev/null 2>&1
do

    RETRY=$((RETRY + 1))

    if [ "${RETRY}" -ge "${MAX_RETRIES}" ]; then
        echo "[ERREUR] Impossible de joindre ${DB_HOST}:${DB_PORT}"
        exit 1
    fi

    sleep 2
done

echo "[OK] Base de données accessible."

###############################################################################
# VERIFICATION DE L'HOTE
###############################################################################

if [ ! -d /host ]; then
    echo "[ERREUR] Le système de fichiers de l'hôte n'est pas monté."
    exit 1
fi

echo "[OK] Système de fichiers de l'hôte accessible."

###############################################################################
# LANCEMENT COLLECTOR
###############################################################################

cd /opt/sentinelle/bash

echo "[INFO] Lancement du collector Sentinelle..."

exec /bin/bash /opt/sentinelle/bash/collector.sh
