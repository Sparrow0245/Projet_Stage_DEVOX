#!/bin/bash
###############################################################################
# Sentinelle V4 - Analyse Sécurité Tentatives d'accès SSH
# Emplacement : monitoring/04_sentinelle_supervision_securisee/bash/collect/collect_ssh.sh
###############################################################################
set -euo pipefail

DB_CNF="/etc/mysql/sentinelle.cnf"

# Détection des échecs d'authentification SSH sur les 5 dernières minutes
FAILED_ATTEMPTS=$(journalctl -u ssh --since "5 minutes ago" 2>/dev/null | grep -c "Failed password" || echo 0)

if [ "${FAILED_ATTEMPTS}" -gt 0 ]; then
    mysql --defaults-extra-file="${DB_CNF}" sentinelle -e \
    "INSERT INTO events (host_id, event_type, severity, message) \
    VALUES (1, 'AUTH_FAILURE', 'CRITICAL', 'Alerte sécurité SSH : ${FAILED_ATTEMPTS} échec(s) de connexion détecté(s).');"
fi
