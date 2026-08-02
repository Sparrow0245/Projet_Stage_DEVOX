#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Configuration MariaDB/MySQL pour Sentinelle V4
###############################################################################

set -euo pipefail

echo ">>> Initialisation et configuration de la base de données MariaDB..."

DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

# Création de la BDD et des privilèges
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mariadb -e "CREATE USER IF NOT EXISTS 'sentinelle_user'@'localhost' IDENTIFIED BY 'Sentinelle2026!';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO 'sentinelle_user'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# Structure des tables
sudo mariadb "${DB_NAME}" << 'EOF'
CREATE TABLE IF NOT EXISTS hosts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    cpu_usage DOUBLE NOT NULL DEFAULT 0,
    ram_usage DOUBLE NOT NULL DEFAULT 0,
    disk_usage DOUBLE NOT NULL DEFAULT 0,
    swap_usage DOUBLE NOT NULL DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'INFO',
    status VARCHAR(50) DEFAULT 'active',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS services_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO hosts (id, hostname, ip_address) VALUES (1, 'localhost', '127.0.0.1')
ON DUPLICATE KEY UPDATE id=1;

-- Donnée initiale pour alimenter le Dashboard et valider la recette
INSERT INTO metrics (host_id, cpu_usage, ram_usage, disk_usage, swap_usage)
VALUES (1, 15.0, 42.0, 35.0, 0.0);
EOF

echo "[SUCCÈS] Base de données 'sentinelle' et tables initialisées."
