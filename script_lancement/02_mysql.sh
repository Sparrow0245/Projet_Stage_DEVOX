#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle
###############################################################################

set -euo pipefail


echo "==============================================================="
echo " Configuration base de données Sentinelle"
echo "==============================================================="


###############################################################################
# Variables
###############################################################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DB_NAME="sentinelle"
DB_USER="sentinelle"
DB_PASSWORD="serveur"

SQL_FILE="${BASE_DIR}/monitoring/database/sentinelle.sql"



###############################################################################
# Vérification root
###############################################################################

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi



###############################################################################
# Vérification fichier SQL
###############################################################################

if [[ ! -f "${SQL_FILE}" ]]; then
    echo "[ERREUR] Fichier SQL introuvable :"
    echo "${SQL_FILE}"
    exit 1
fi



###############################################################################
# Vérification MariaDB
###############################################################################

if ! systemctl is-active --quiet mariadb; then

    echo "[INFO] Démarrage MariaDB"

    systemctl start mariadb

fi



###############################################################################
# Création base et utilisateur
###############################################################################

echo
echo "[1/4] Création base de données et utilisateur"



mysql <<EOF

CREATE DATABASE IF NOT EXISTS ${DB_NAME}
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;


CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASSWORD}';


ALTER USER '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASSWORD}';


GRANT ALL PRIVILEGES
ON ${DB_NAME}.*
TO '${DB_USER}'@'localhost';


FLUSH PRIVILEGES;


EOF



echo "[OK] Base et utilisateur configurés"



###############################################################################
# Import du schéma SQL
###############################################################################

echo
echo "[2/4] Import du schéma SQL"


mysql \
-u "${DB_USER}" \
-p"${DB_PASSWORD}" \
"${DB_NAME}" \
< "${SQL_FILE}"



echo "[OK] Schéma importé"



###############################################################################
# Vérification des tables
###############################################################################

echo
echo "[3/4] Vérification des tables"


TABLES=$(mysql \
-u "${DB_USER}" \
-p"${DB_PASSWORD}" \
"${DB_NAME}" \
-e "SHOW TABLES;")


echo "${TABLES}"



REQUIRED_TABLES=(
    "metrics"
    "events"
    "bans"
    "users"
)


for TABLE in "${REQUIRED_TABLES[@]}"
do

    if echo "${TABLES}" | grep -q "${TABLE}"
    then
        echo "[OK] Table ${TABLE} présente"
    else
        echo "[ERREUR] Table ${TABLE} absente"
        exit 1
    fi

done



###############################################################################
# Test connexion applicative
###############################################################################

echo
echo "[4/4] Test connexion utilisateur Sentinelle"


mysql \
-u "${DB_USER}" \
-p"${DB_PASSWORD}" \
"${DB_NAME}" \
-e "SELECT NOW();" > /dev/null



echo "[OK] Connexion fonctionnelle"



echo
echo "==============================================================="
echo " Base de données Sentinelle prête"
echo "==============================================================="
