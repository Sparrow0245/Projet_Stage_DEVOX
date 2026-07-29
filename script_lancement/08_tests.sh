#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Tests de validation de l'installation V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Tests de validation Sentinelle V4"
echo "==============================================================="

SUCCESS=0
FAILED=0

check() {
    DESCRIPTION="$1"
    COMMAND="$2"
    echo -n "[TEST] ${DESCRIPTION} : "
    if eval "${COMMAND}" >/dev/null 2>&1; then
        echo "OK"
        SUCCESS=$((SUCCESS+1))
    else
        echo "ECHEC"
        FAILED=$((FAILED+1))
    fi
}

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo
echo "---- Services système ----"
check "Apache actif" "systemctl is-active apache2"
check "MariaDB actif" "systemctl is-active mariadb"
check "Backend Spring Boot actif" "systemctl is-active sentinelle-backend.service"
check "Timer de collecte actif" "systemctl is-active sentinelle-monitor.timer"

echo
echo "---- Base de données ----"
check "Connexion MySQL automatique" "mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf sentinelle -e 'SELECT 1;'"

echo
echo "---- Endpoints & Frontend ----"
check "Frontend Web accessible" "curl -k -I https://localhost/index.html"
check "API Backend via Reverse Proxy" "curl -k -s https://localhost/api/dashboard/overview | grep -q UP"

echo
echo "==============================================================="
echo " Tests réussis : ${SUCCESS} | Échecs : ${FAILED}"
echo "==============================================================="

if [[ ${FAILED} -eq 0 ]]; then
    exit 0
else
    exit 1
fi
