###############################################################################
-- SENTINELLE V4
-- Schéma MariaDB Docker
###############################################################################

CREATE DATABASE IF NOT EXISTS sentinelle
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE sentinelle;

###############################################################################
-- HOTES
###############################################################################

CREATE TABLE IF NOT EXISTS hosts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    status ENUM('online', 'offline', 'warning') DEFAULT 'online',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

###############################################################################
-- METRIQUES
###############################################################################

CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    cpu_usage DOUBLE NOT NULL DEFAULT 0,
    ram_usage DOUBLE NOT NULL DEFAULT 0,
    disk_usage DOUBLE NOT NULL DEFAULT 0,
    swap_usage DOUBLE NOT NULL DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_metrics_host_timestamp (host_id, timestamp),

    CONSTRAINT fk_metrics_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

###############################################################################
-- SERVICES
###############################################################################

CREATE TABLE IF NOT EXISTS services_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'inactive',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY unique_host_service (host_id, service_name),

    CONSTRAINT fk_services_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

###############################################################################
-- EVENEMENTS
###############################################################################

CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id BIGINT NOT NULL DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'INFO',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_events_host_created (host_id, created_at),

    CONSTRAINT fk_events_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

###############################################################################
-- UTILISATEURS
#
# Le PHP actuel utilise "password".
# Le schéma V4 utilise également password_hash.
# Les deux colonnes sont conservées pour compatibilité.
###############################################################################

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) DEFAULT NULL,
    password_hash VARCHAR(255) DEFAULT NULL,
    totp_secret VARCHAR(64) DEFAULT NULL,
    role ENUM('admin', 'viewer') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

###############################################################################
-- HOTE LOCAL
###############################################################################

INSERT INTO hosts (
    id,
    hostname,
    ip_address,
    status
)
VALUES (
    1,
    'localhost',
    '127.0.0.1',
    'online'
)
ON DUPLICATE KEY UPDATE
    hostname = VALUES(hostname),
    ip_address = VALUES(ip_address);
