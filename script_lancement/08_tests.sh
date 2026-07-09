#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Tests de validation installation Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Tests de validation Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

DB_NAME="sentinelle"
DB_USER="sentinelle"
DB_PASSWORD="serveur"

WEB_DIR="/var/www/html/sentinelle"

SENTINELLE_DIR="/opt/sentinelle"



###############################################################################
# Compteur résultats
###############################################################################

SUCCESS=0
FAILED=0



###############################################################################
# Fonction test
###############################################################################

check()
{
    DESCRIPTION="$1"
    COMMAND="$2"


    echo -n "[TEST] ${DESCRIPTION} : "


    if eval "${COMMAND}" >/dev/null 2>&1
    then

        echo "OK"
        SUCCESS=$((SUCCESS+1))

    else

        echo "ECHEC"
        FAILED=$((FAILED+1))

    fi

}



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then

    echo "[ERREUR] Ce script doit être exécuté avec sudo."

    exit 1

fi



###############################################################################
# Tests fichiers
###############################################################################

echo
echo "---- Vérification fichiers ----"


check \
"Répertoire Sentinelle présent" \
"test -d ${SENTINELLE_DIR}"


check \
"Script Sentinelle présent" \
"test -f ${SENTINELLE_DIR}/sentinelle.sh"


check \
"Répertoire Web présent" \
"test -d ${WEB_DIR}"


check \
"Dashboard présent" \
"test -f ${WEB_DIR}/index.php"


check \
"Historique présent" \
"test -f ${WEB_DIR}/historique.php"



###############################################################################
# Tests services
###############################################################################

echo
echo "---- Vérification services ----"



check \
"Apache actif" \
"systemctl is-active apache2"



check \
"MariaDB actif" \
"systemctl is-active mariadb"



check \
"Service Sentinelle actif" \
"systemctl is-active sentinelle"



check \
"Timer collecteur actif" \
"systemctl is-active sentinelle-collector.timer"



###############################################################################
# Tests base de données
###############################################################################

echo
echo "---- Vérification base de données ----"



check \
"Connexion MySQL Sentinelle" \
"mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -e 'SELECT 1;'"



TABLES=(
    "metrics"
    "events"
    "bans"
    "users"
)



for TABLE in "${TABLES[@]}"
do

    check \
    "Table ${TABLE}" \
    "mysql -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} -e 'SHOW TABLES;' | grep -q ${TABLE}"

done



###############################################################################
# Tests HTTP
###############################################################################

echo
echo "---- Vérification HTTP ----"



check \
"Apache répond en local" \
"curl -I http://localhost/sentinelle"



check \
"Page dashboard accessible" \
"curl -s http://localhost/sentinelle/index.php | grep -q html"



###############################################################################
# Résultat final
###############################################################################

echo
echo "==============================================================="

echo " Résultat"

echo "==============================================================="

echo

echo "Tests réussis : ${SUCCESS}"

echo "Tests échoués : ${FAILED}"

echo


if [[ ${FAILED} -eq 0 ]]
then

    echo "==============================================================="
    echo " Installation validée avec succès"
    echo "==============================================================="

    exit 0

else

    echo "==============================================================="
    echo " Des erreurs ont été détectées"
    echo " Vérifier les logs avant utilisation"
    echo "==============================================================="

    exit 1

fi
