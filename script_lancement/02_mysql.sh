#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Configuration base de données Sentinelle V4"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee"

DB_NAME="sentinelle"
DB_USER="sentinelle"
DB_PASSWORD="SentinelleSecurePass2026!"
SQL_FILE="${APP_DIR}/database/sentinelle.sql"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

if [[ ! -f "${SQL_FILE}" ]]; then
    echo "[ERREUR] Fichier SQL introuvable : ${SQL_FILE}"
    exit 1
fi

if ! systemctl is-active --quiet mariadb; then
    echo "[INFO] Démarrage MariaDB"
    systemctl start mariadb
fi

echo
echo "[1/4] Création base de données et utilisateur"

mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[OK] Base et utilisateur configurés"

echo
echo "[2/4] Import du schéma SQL"
mysql -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < "${SQL_FILE}"
echo "[OK] Schéma V4 importé"

echo
echo "[3/4] Fichier d'authentification automatique pour les scripts Bash"
mkdir -p /etc/mysql
cat <<EOF > /etc/mysql/sentinelle.cnf
[client]
user=${DB_USER}
password=${DB_PASSWORD}
host=localhost
EOF
chmod 600 /etc/mysql/sentinelle.cnf

echo
echo "[4/4] Test connexion utilisateur Sentinelle"
mysql --defaults-extra-file=/etc/mysql/sentinelle.cnf "${DB_NAME}" -e "SELECT NOW();" > /dev/null
echo "[OK] Connexion fonctionnelle"

echo
echo "==============================================================="
echo " Base de données Sentinelle V4 prête"
echo "==============================================================="
