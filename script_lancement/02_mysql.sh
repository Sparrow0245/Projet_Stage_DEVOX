#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle V4
###############################################################################

#!/bin/bash

set -euo pipefail

echo ">>> Initialisation et configuration de la base de données MariaDB..."

DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

# Création de la BDD et des privilèges utilisateur
mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mariadb -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mariadb -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mariadb -u root -e "FLUSH PRIVILEGES;"

# Structure de la table metrics
mariadb -u root "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cpu_usage FLOAT DEFAULT 0,
    ram_usage FLOAT DEFAULT 0,
    disk_usage FLOAT DEFAULT 0,
    swap_usage FLOAT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Structure de la table events
mariadb -u root "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

echo "[SUCCÈS] Base de données 'sentinelle' et tables initialisées."
echo
echo "==============================================================="
echo " Base de données Sentinelle V4 prête"
echo "==============================================================="
