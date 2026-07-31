-- ===============================================================
-- Sentinelle V4 - Initialisation de la Base de Données (Mise à jour 2FA)
-- Fichier : monitoring/04_sentinelle_supervision_securisee/database/sentinelle.sql
-- ===============================================================

CREATE DATABASE IF NOT EXISTS sentinelle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sentinelle;

-- 1. Table des hôtes surveillés
CREATE TABLE IF NOT EXISTS hosts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL DEFAULT 'localhost',
    ip_address VARCHAR(45) NOT NULL DEFAULT '127.0.0.1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO hosts (id, hostname, ip_address)
VALUES (1, 'localhost', '127.0.0.1')
ON DUPLICATE KEY UPDATE hostname='localhost';

-- 2. Table unifiée des métriques
CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL DEFAULT 1,
    cpu_usage DECIMAL(5,2) DEFAULT 0.00,
    ram_usage DECIMAL(5,2) DEFAULT 0.00,
    disk_usage DECIMAL(5,2) DEFAULT 0.00,
    swap_usage DECIMAL(5,2) DEFAULT 0.00,
    network_rx_kb BIGINT DEFAULT 0,
    network_tx_kb BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES hosts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. Table des événements et alertes
CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL DEFAULT 1,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'INFO',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES hosts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Table des statuts de services Systemd
CREATE TABLE IF NOT EXISTS services_status (
    host_id INT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (host_id, service_name),
    FOREIGN KEY (host_id) REFERENCES hosts(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Table des utilisateurs avec support Google Authenticator (TOTP)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    totp_secret VARCHAR(32) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Compte Administrateur par défaut avec secret TOTP de test (Exemple: JBSWY3DPEHPK3PXP)
INSERT INTO users (username, password, role, totp_secret) 
VALUES ('admin', '$2a$10$e8R1/m6/4Hj.6dJkO4f1m.8x9U0Z2E4Y6X8W0V2U4T6R8P0N2M4L6', 'ADMIN', 'JBSWY3DPEHPK3PXP')
ON DUPLICATE KEY UPDATE id=id;
