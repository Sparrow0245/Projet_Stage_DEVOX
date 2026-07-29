CREATE DATABASE IF NOT EXISTS sentinelle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sentinelle;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER',
    totp_secret VARCHAR(255),
    totp_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Métriques CPU
CREATE TABLE IF NOT EXISTS metrics_cpu (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usage_percent FLOAT NOT NULL,
    frequency_mhz FLOAT,
    cores_count INT,
    temperature FLOAT,
    load_1m FLOAT,
    load_5m FLOAT,
    load_15m FLOAT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cpu_recorded (recorded_at)
) ENGINE=InnoDB;

-- Métriques RAM & Swap
CREATE TABLE IF NOT EXISTS metrics_ram (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    total_mb BIGINT NOT NULL,
    used_mb BIGINT NOT NULL,
    free_mb BIGINT NOT NULL,
    cached_mb BIGINT,
    swap_total_mb BIGINT,
    swap_used_mb BIGINT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ram_recorded (recorded_at)
) ENGINE=InnoDB;

-- Métriques Disque
CREATE TABLE IF NOT EXISTS metrics_disk (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    mount_point VARCHAR(255) NOT NULL,
    total_gb FLOAT NOT NULL,
    used_gb FLOAT NOT NULL,
    free_gb FLOAT NOT NULL,
    usage_percent FLOAT NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_disk_recorded (recorded_at)
) ENGINE=InnoDB;

-- Métriques Réseau
CREATE TABLE IF NOT EXISTS metrics_network (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    interface_name VARCHAR(50) NOT NULL,
    rx_bytes BIGINT NOT NULL,
    tx_bytes BIGINT NOT NULL,
    rx_errors INT DEFAULT 0,
    tx_errors INT DEFAULT 0,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_net_recorded (recorded_at)
) ENGINE=InnoDB;

-- Événements Sécurité & SSH
CREATE TABLE IF NOT EXISTS ssh_events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    username VARCHAR(50),
    ip_address VARCHAR(45) NOT NULL,
    port INT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ssh_recorded (recorded_at)
) ENGINE=InnoDB;

-- Historique Général
CREATE TABLE IF NOT EXISTS history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    action VARCHAR(255) NOT NULL,
    performed_by VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45),
    details TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_history_recorded (recorded_at)
) ENGINE=InnoDB;

-- Alertes Système
CREATE TABLE IF NOT EXISTS alerts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alerts_level (level)
) ENGINE=InnoDB;

-- Procédure de nettoyage automatique
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS CleanOldMetrics(IN days_retention INT)
BEGIN
    DELETE FROM metrics_cpu WHERE recorded_at < NOW() - INTERVAL days_retention DAY;
    DELETE FROM metrics_ram WHERE recorded_at < NOW() - INTERVAL days_retention DAY;
    DELETE FROM metrics_disk WHERE recorded_at < NOW() - INTERVAL days_retention DAY;
    DELETE FROM metrics_network WHERE recorded_at < NOW() - INTERVAL days_retention DAY;
END //
DELIMITER ;
