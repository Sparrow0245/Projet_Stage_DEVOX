-- ===================================================
-- Base de Données - Sentinelle V4
-- Emplacement GitHub : monitoring/04_sentinelle_supervision_securisee/database/sentinelle.sql
-- Destination VM     : Import MariaDB / MySQL
-- ===================================================

CREATE DATABASE IF NOT EXISTS `sentinelle` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `sentinelle`;

-- 1. Table des Hôtes surveillés
CREATE TABLE IF NOT EXISTS `hosts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `hostname` VARCHAR(255) NOT NULL,
    `ip_address` VARCHAR(45) NOT NULL,
    `status` ENUM('online', 'offline', 'warning') DEFAULT 'online',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Table des Métriques système (CPU, RAM, Disque, SWAP)
CREATE TABLE IF NOT EXISTS `metrics` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT NOT NULL DEFAULT 1,
    `cpu_usage` DECIMAL(5,2) NOT NULL,
    `ram_usage` DECIMAL(5,2) NOT NULL,
    `disk_usage` DECIMAL(5,2) NOT NULL,
    `swap_usage` DECIMAL(5,2) DEFAULT 0.00,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3. Table des Statuts des Services Monitorés
CREATE TABLE IF NOT EXISTS `services_status` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT NOT NULL DEFAULT 1,
    `service_name` VARCHAR(100) NOT NULL,
    `status` ENUM('active', 'inactive', 'failed') NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. Table des Événements & Alertes
CREATE TABLE IF NOT EXISTS `events` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `host_id` INT NOT NULL DEFAULT 1,
    `type` ENUM('INFO', 'WARNING', 'CRITICAL') NOT NULL,
    `message` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`host_id`) REFERENCES `hosts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5. Table des Utilisateurs (Gestion Sessions JWT & 2FA TOTP)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) UNIQUE NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `totp_secret` VARCHAR(64) DEFAULT NULL,
    `role` ENUM('admin', 'viewer') DEFAULT 'admin',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Insertion de l'hôte local par défaut
INSERT INTO `hosts` (`id`, `hostname`, `ip_address`, `status`)
VALUES (1, 'localhost', '127.0.0.1', 'online')
ON DUPLICATE KEY UPDATE `hostname` = VALUES(`hostname`);

-- Utilisateur Administrateur par défaut (mot de passe initial : AdminSentinelle2026!)
INSERT INTO `users` (`username`, `password_hash`, `role`)
VALUES ('admin', '$2y$10$e8N0X1u.zY7yGzYp8x7Z0uO8bK5Wn7vY1X3Z5e7Y9K1b3Z5e7Y9K1', 'admin')
ON DUPLICATE KEY UPDATE `role` = 'admin';
