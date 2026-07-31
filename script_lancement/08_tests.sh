#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Script 08 - Tests de validation et recette du système
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " [08/09] Recette et vérification de la plateforme Sentinelle V4"
echo "==============================================================="

ERRORS=0

# 1. Test de la base de données MariaDB
echo -n "[TEST 1/5] Connexion Base de Données 'sentinelle'... "
if mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf sentinelle -e "SELECT 1;" &>/dev/null; then
    echo "OK"
else
    echo "ÉCHEC"
    ERRORS=$((ERRORS + 1))
fi

# 2. Test d'exécution du Collector
echo -n "[TEST 2/5] Exécution du script de collecte... "
COLLECTOR="/opt/sentinelle/bash/collector.sh"

if [[ -f "${COLLECTOR}" ]] && bash "${COLLECTOR}" &>/dev/null; then
    echo "OK"
else
    echo "ÉCHEC"
    ERRORS=$((ERRORS + 1))
fi

# 3. Test de présence des métriques en BDD
echo -n "[TEST 3/5] Vérification de l'insertion des métriques... "
METRIC_COUNT=$(mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf sentinelle -N -e "SELECT COUNT(*) FROM metrics;" 2>/dev/null || echo 0)
if [ "${METRIC_COUNT}" -gt 0 ]; then
    echo "OK (${METRIC_COUNT} entrées)"
else
    echo "ÉCHEC"
    ERRORS=$((ERRORS + 1))
fi

# 4. Test des Services Systemd
echo -n "[TEST 4/5] État des services Systemd... "
if systemctl is-active --quiet apache2 && systemctl is-active --quiet mariadb; then
    echo "OK (Apache2 & MariaDB actifs)"
else
    echo "AVERTISSEMENT (Un ou plusieurs services inactifs)"
fi

# 5. Test de l'API Web PHP (port 8080)
echo -n "[TEST 5/5] Accessibilité de l'API Web metrics.php... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/metrics.php || echo "000")
if [ "${HTTP_CODE}" -eq 200 ]; then
    echo "OK (HTTP 200)"
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
