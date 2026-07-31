#!/bin/bash

###############################################################################
# Dépôt : Projet_Stage_DEVOX
# Fichier : monitoring/scripts/insertion_bdd.sh
###############################################################################

DB_USER="sentinelle"
DB_PASS="SentinelleSecurePass2026!"
DB_NAME="sentinelle"

TYPE="${1:-}"

if [ "$TYPE" = "metrics" ]; then
    CPU="${2:-0}"
    RAM="${3:-0}"
    DISK="${4:-0}"
    SWAP="${5:-0}"

    mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOF 2>/dev/null
CREATE TABLE IF NOT EXISTS metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cpu_usage FLOAT NOT NULL,
    ram_usage FLOAT NOT NULL,
    disk_usage FLOAT NOT NULL,
    swap_usage FLOAT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO metrics (cpu_usage, ram_usage, disk_usage, swap_usage)
VALUES (${CPU}, ${RAM}, ${DISK}, ${SWAP});
EOF

elif [ "$TYPE" = "event" ]; then
    EVT_TYPE="${2:-INFO}"
    SEVERITY="${3:-LOW}"
    MESSAGE="${4:-}"

    mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOF 2>/dev/null
CREATE TABLE IF NOT EXISTS events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO events (type, severity, message)
VALUES ('${EVT_TYPE}', '${SEVERITY}', '${MESSAGE}');
EOF
fi
