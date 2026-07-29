#!/bin/bash

###############################################################################
# Sentinelle V4 - Vérification de l'état des services critiques systemd
###############################################################################

set -euo pipefail

MYSQL_CONF="/etc/mysql/sentinelle.cnf"
DB_NAME="sentinelle"

SERVICES=("apache2" "mariadb" "ufw" "apparmor" "sshd")

for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "${SERVICE}"; then
        STATUS="ACTIVE"
    else
        STATUS="INACTIVE"
    fi
    
    mysql --defaults-extra-file="${MYSQL_CONF}" "${DB_NAME}" -e \
    "INSERT INTO system_services (service_name, status, checked_at) 
     VALUES ('${SERVICE}', '${STATUS}', NOW()) 
     ON DUPLICATE KEY UPDATE status='${STATUS}', checked_at=NOW();" 2>/dev/null || true
done
