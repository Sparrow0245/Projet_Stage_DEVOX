#!/bin/bash

###############################################################################
# Sentinelle V4 - Entrypoint Backend
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Sentinelle V4 - Backend Spring Boot"
echo "==============================================================="

echo "[INFO] Attente de la base de données..."

MAX_RETRIES=60
RETRY=0

until bash -c "exec 3<>/dev/tcp/${DB_HOST}/${DB_PORT}" 2>/dev/null
do
    RETRY=$((RETRY + 1))

    if [ "${RETRY}" -ge "${MAX_RETRIES}" ]; then
        echo "[ERREUR] Impossible de joindre ${DB_HOST}:${DB_PORT}"
        exit 1
    fi

    sleep 2
done

echo "[OK] Base de données accessible."

exec java \
    -jar /opt/sentinelle/sentinelle-backend.jar \
    --server.port="${SERVER_PORT:-8080}" \
    --spring.datasource.url="${SPRING_DATASOURCE_URL}" \
    --spring.datasource.username="${SPRING_DATASOURCE_USERNAME}" \
    --spring.datasource.password="${SPRING_DATASOURCE_PASSWORD}" \
    --spring.jpa.hibernate.ddl-auto="${SPRING_JPA_HIBERNATE_DDL_AUTO:-validate}" \
    --jwt.secret="${JWT_SECRET}" \
    --jwt.expiration="${JWT_EXPIRATION:-28800}"
