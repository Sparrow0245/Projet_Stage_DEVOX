-- ===============================================================
-- Projet Sentinelle V4 - Base de données & Authentification RBAC
-- Emplacement : monitoring/04_sentinelle_supervision_securisee/database/sentinelle.sql
-- ===============================================================

CREATE DATABASE IF NOT EXISTS `sentinelle` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `sentinelle`;

-- 1. Table des Utilisateurs (Gestion des Rôles Admin / User)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('admin', 'user') DEFAULT 'user',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Table des Hôtes surveillés
CREATE TABLE IF NOT EXISTS `hosts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `hostname` VARCHAR(255) NOT NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `os_info` VARCHAR(255) DEFAULT NULL,
    `status` ENUM('UP', 'DOWN', 'WARNING') DEFAULT 'UP',
    `last_ping` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Table des Métriques Système
CREATE TABLE IF NOT EXISTS `metrics` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT DEFAULT 1,
    `cpu_usage` FLOAT NOT NULL,
    `ram_usage` FLOAT NOT NULL,
    `disk_usage` FLOAT NOT NULL,
    `swap_usage` FLOAT DEFAULT 0.0,
    `network_rx_kb` BIGINT DEFAULT 0,
    `network_tx_kb` BIGINT DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_metrics_created_at` (`created_at`),
    CONSTRAINT `fk_metrics_host` FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Table des Services Système (Apache, MariaDB, SSH, Backend)
CREATE TABLE IF NOT EXISTS `services_status` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT DEFAULT 1,
    `service_name` VARCHAR(100) NOT NULL,
    `status` ENUM('ACTIVE', 'INACTIVE', 'FAILED') NOT NULL,
    `last_check` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_host_service` (`host_id`, `service_name`),
    CONSTRAINT `fk_services_host` FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Table des Événements et Alertes de Sécurité
CREATE TABLE IF NOT EXISTS `events` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT DEFAULT 1,
    `event_type` VARCHAR(50) NOT NULL,
    `severity` ENUM('INFO', 'WARNING', 'CRITICAL') DEFAULT 'INFO',
    `message` TEXT NOT NULL,
    `is_acknowledged` TINYINT(1) DEFAULT 0,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_events_severity` (`severity`),
    CONSTRAINT `fk_events_host` FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Table des Seuils d'Alerte
CREATE TABLE IF NOT EXISTS `alert_thresholds` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `metric_name` VARCHAR(50) UNIQUE NOT NULL,
    `warning_threshold` FLOAT NOT NULL,
    `critical_threshold` FLOAT NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------
-- Données Initiales (Compte Administrateur par défaut)
-- Identifiants Admin : admin / Admin2026!
-- ---------------------------------------------------------------

INSERT INTO `users` (`username`, `password`, `role`) VALUES
('admin', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe10pY2q/K3wYV3nQ7O7a7N7r4O0Gv5CS', 'admin')
ON DUPLICATE KEY UPDATE `role`='admin';

INSERT INTO `hosts` (`id`, `hostname`, `ip_address`, `os_info`) VALUES
(1, 'localhost', '127.0.0.1', 'Ubuntu Server V4')
ON DUPLICATE KEY UPDATE `hostname`=`hostname`;

INSERT INTO `alert_thresholds` (`metric_name`, `warning_threshold`, `critical_threshold`) VALUES
('cpu', 80.0, 95.0),
('ram', 85.0, 95.0),
('disk', 85.0, 90.0)
ON DUPLICATE KEY UPDATE `warning_threshold`=`warning_threshold`;

INSERT INTO `services_status` (`host_id`, `service_name`, `status`) VALUES
(1, 'apache2', 'ACTIVE'),
(1, 'mariadb', 'ACTIVE'),
(1, 'sentinelle-backend', 'ACTIVE'),
(1, 'ssh', 'ACTIVE')
ON DUPLICATE KEY UPDATE `status`=`status`;
