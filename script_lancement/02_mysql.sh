#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle V4
###############################################################################

set -euo pipefail

echo ">>> Initialisation et configuration de la base de données MariaDB..."

# Création de la base de données
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS sentinelle;"

# Création des deux comptes pour couvrir sentinelle.cnf et application.properties
sudo mariadb -e "CREATE USER IF NOT EXISTS 'sentinelle'@'localhost' IDENTIFIED BY 'SentinelleSecurePass2026!';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON sentinelle.* TO 'sentinelle'@'localhost';"

sudo mariadb -e "CREATE USER IF NOT EXISTS 'sentinelle_user'@'localhost' IDENTIFIED BY 'Sentinelle2026!';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON sentinelle.* TO 'sentinelle_user'@'localhost';"

sudo mariadb -e "FLUSH PRIVILEGES;"

# Structure table hosts
sudo mariadb sentinelle -e "
CREATE TABLE IF NOT EXISTS hosts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Structure table metrics
sudo mariadb sentinelle -e "
CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    cpu_usage DOUBLE NOT NULL DEFAULT 0,
    ram_usage DOUBLE NOT NULL DEFAULT 0,
    disk_usage DOUBLE NOT NULL DEFAULT 0,
    swap_usage DOUBLE NOT NULL DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Structure table events
sudo mariadb sentinelle -e "
CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'INFO',
    status VARCHAR(50) DEFAULT 'active',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Structure table services_status
sudo mariadb sentinelle -e "
CREATE TABLE IF NOT EXISTS services_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);"

# Injection de l'hôte par défaut pour la clé étrangère host_id
sudo mariadb sentinelle -e "
INSERT INTO hosts (id, hostname, ip_address) VALUES (1, 'localhost', '127.0.0.1')
ON DUPLICATE KEY UPDATE id=1;
"

echo "==============================================================="
echo " Base de données Sentinelle V4 prête"
echo "==============================================================="
