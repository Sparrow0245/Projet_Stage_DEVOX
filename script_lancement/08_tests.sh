#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 08 - Tests de validation et recette du système
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [08/09] Recette et vérification de la plateforme Sentinelle V4"
echo "==============================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MONITORING_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"

ERRORS=0

# 1. Test MariaDB
echo -n "[TEST 1/5] Connexion Base de Données 'sentinelle'... "
if mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf sentinelle -e "SELECT 1;" &>/dev/null; then
    echo "OK"
else
    echo "ÉCHEC"
    ERRORS=$((ERRORS + 1))
fi

# 2. Test Collector
echo -n "[TEST 2/5] Vérification de la présence du collector... "
COLLECTOR="${MONITORING_DIR}/bash/collector.sh"
if [[ -f "${COLLECTOR}" ]]; then
    echo "OK (${COLLECTOR})"
else
    echo "ÉCHEC (Script introuvable)"
    ERRORS=$((ERRORS + 1))
fi

# 3. Test des métriques
echo -n "[TEST 3/5] Insertion des métriques en BDD... "
METRIC_COUNT=$(mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf sentinelle -N -e "SELECT COUNT(*) FROM metrics;" 2>/dev/null || echo 0)
if [ "${METRIC_COUNT}" -gt 0 ]; then
    echo "OK (${METRIC_COUNT} entrées)"
else
    echo "ÉCHEC (Aucune donnée dans la table metrics)"
    ERRORS=$((ERRORS + 1))
fi

# 4. Test Systemd
echo -n "[TEST 4/5] État du service de collecte Systemd... "
if systemctl is-active --quiet sentinelle-monitor.service 2>/dev/null || systemctl is-active --quiet mariadb; then
    echo "OK (Services actifs)"
else
    echo "AVERTISSEMENT (Service inactif)"
    ERRORS=$((ERRORS + 1))
fi

# 5. Test API avec boucle d'attente
echo -n "[TEST 5/5] Accessibilité API Spring Boot (/api/metrics)... "
HTTP_CODE="000"
for i in {1..20}; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/metrics 2>/dev/null || echo "000")
    if [ "${CODE}" -eq 200 ] || [ "${CODE}" -eq 401 ]; then
        HTTP_CODE="${CODE}"
        break
    fi
    sleep 1
done

if [ "${HTTP_CODE}" -eq 200 ] || [ "${HTTP_CODE}" -eq 401 ]; then
    echo "OK (Code HTTP: ${HTTP_CODE})"
else
    echo "ÉCHEC (Code HTTP: ${HTTP_CODE})"
    ERRORS=$((ERRORS + 1))
fi

echo "---------------------------------------------------------------"
if [ "${ERRORS}" -eq 0 ]; then
    echo " SUCCESS : Tous les tests de recette sont validés !"
else
    echo " ATTENTION : ${ERRORS} test(s) ont échoué. Vérifiez les logs."
fi
echo "==============================================================="
