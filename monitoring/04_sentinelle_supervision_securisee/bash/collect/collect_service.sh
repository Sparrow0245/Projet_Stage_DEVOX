#!/bin/bash
###############################################################################
# Sentinelle V4 - Contrôle des Services Systemd
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_service.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"
SERVICES=("apache2" "mariadb" "sentinelle-backend" "ssh")

for SVC in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "${SVC}"; then
        STATUS="active"
    else
        STATUS="failed"
        mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
        "INSERT INTO events (host_id, type, message) \
        VALUES (1, 'CRITICAL', 'Le service système ${SVC} est inactif ou en échec !');"
    fi

    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO services_status (host_id, service_name, status) \
    VALUES (1, '${SVC}', '${STATUS}') \
    ON DUPLICATE KEY UPDATE status='${STATUS}', updated_at=NOW();"
done
