#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle V4
###############################################################################

set -euo pipefail

echo ">>> Initialisation et configuration de la base de données MariaDB..."

DB_USER="sentinelle_user"
DB_PASS="Sentinelle2026!"
DB_NAME="sentinelle"

# Création de la BDD et des privilèges utilisateur
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# 1. Table hosts
sudo mariadb "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS hosts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# 2. Table metrics (avec host_id et double/float)
sudo mariadb "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    cpu_usage DOUBLE NOT NULL DEFAULT 0,
    ram_usage DOUBLE NOT NULL DEFAULT 0,
    disk_usage DOUBLE NOT NULL DEFAULT 0,
    swap_usage DOUBLE NOT NULL DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# 3. Table events (avec host_id et status)
sudo mariadb "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# 4. Table services_status (requise par le collector)
sudo mariadb "${DB_NAME}" -e "
CREATE TABLE IF NOT EXISTS services_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);"

# Injection de l'hôte par défaut
sudo mariadb "${DB_NAME}" -e "
INSERT INTO hosts (id, hostname, ip_address) VALUES (1, 'localhost', '127.0.0.1')
ON DUPLICATE KEY UPDATE id=1;
"

echo "[SUCCÈS] Base de données 'sentinelle' et tables initialisées."
echo "==============================================================="
echo " Base de données Sentinelle V4 prête"
echo "==============================================================="
