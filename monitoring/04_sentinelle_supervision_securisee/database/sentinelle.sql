CREATE DATABASE IF NOT EXISTS sentinelle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sentinelle;

-- Table des utilisateurs pour l'accès Web
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Force la suppression de la table si elle existe pour recréer la bonne structure
DROP TABLE IF EXISTS metrics_cpu;

-- Table des métriques CPU avec le nom de colonne exact attendu par Hibernate (load_average1m)
CREATE TABLE metrics_cpu (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usage_percent DOUBLE NOT NULL,
    load_average1m DOUBLE NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cpu_recorded_at (recorded_at)
) ENGINE=InnoDB;

-- Table des événements SSH
CREATE TABLE IF NOT EXISTS ssh_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    username VARCHAR(100),
    status VARCHAR(20) NOT NULL, -- SUCCESS / FAILED
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ssh_ip (ip_address)
) ENGINE=InnoDB;

-- Table de surveillance des services système
CREATE TABLE IF NOT EXISTS system_services (
    service_name VARCHAR(100) PRIMARY KEY,
    status VARCHAR(20) NOT NULL, -- ACTIVE / INACTIVE
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Insertion de l'utilisateur administrateur par défaut
INSERT INTO users (username, password, role) 
VALUES ('admin', '$2a$10$e8R1/m6/4Hj.6dJkO4f1m.8x9U0Z2E4Y6X8W0V2U4T6R8P0N2M4L6', 'ADMIN')
ON DUPLICATE KEY UPDATE id=id;
