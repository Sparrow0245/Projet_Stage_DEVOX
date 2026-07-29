#!/bin/bash

###############################################################################
# Sentinelle V4 - Collecte des événements SSH
# Analyse /var/log/auth.log et extrait les échecs / connexions SSH
###############################################################################

set -euo pipefail

AUTH_LOG="/var/log/auth.log"
MYSQL_CONF="/etc/mysql/sentinelle.cnf"
DB_NAME="sentinelle"

if [[ ! -f "${AUTH_LOG}" ]]; then
    # Fallback pour rsyslog / systemd journal si journald est utilisé
    journalctl -u ssh --since "10 minutes ago" > /tmp/ssh_temp.log
    AUTH_LOG="/tmp/ssh_temp.log"
fi

# Extraire les tentatives de connexion échouées récentes
grep "Failed password" "${AUTH_LOG}" | tail -n 20 | while read -r line; do
    IP=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
    USER=$(echo "$line" | sed -n 's/.*for \(invalid user \)\?\([^ ]*\).*/\2/p')
    
    if [[ -n "${IP}" ]] && [[ -n "${USER}" ]]; then
        mysql --defaults-extra-file="${MYSQL_CONF}" "${DB_NAME}" -e \
        "INSERT INTO ssh_events (ip_address, username, status, event_time) VALUES ('${IP}', '${USER}', 'FAILED', NOW());" 2>/dev/null || true
    fi
done

# Extraire les connexions réussies récentes
grep "Accepted password" "${AUTH_LOG}" | tail -n 10 | while read -r line; do
    IP=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
    USER=$(echo "$line" | sed -n 's/.*for \([^ ]*\).*/\1/p')
    
    if [[ -n "${IP}" ]] && [[ -n "${USER}" ]]; then
        mysql --defaults-extra-file="${MYSQL_CONF}" "${DB_NAME}" -e \
        "INSERT INTO ssh_events (ip_address, username, status, event_time) VALUES ('${IP}', '${USER}', 'SUCCESS', NOW());" 2>/dev/null || true
    fi
done

rm -f /tmp/ssh_temp.log 2>/dev/null || true
