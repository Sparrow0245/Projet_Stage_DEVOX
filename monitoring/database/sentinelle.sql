CREATE DATABASE IF NOT EXISTS sentinelle;

USE sentinelle;


CREATE TABLE users
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE servers
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(100),
    ip VARCHAR(50),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE metrics
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_id INT,
    cpu FLOAT,
    ram FLOAT,
    disk FLOAT,
    uptime VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(server_id)
    REFERENCES servers(id)
);



CREATE TABLE alerts
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    severity VARCHAR(20),
    message TEXT,

    status VARCHAR(20)
    DEFAULT 'NEW',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE events
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    type VARCHAR(50),

    message TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



INSERT INTO servers
(hostname,ip,status)
VALUES
(
"localhost",
"127.0.0.1",
"ACTIVE"
);


-- =========================================
-- Tables monitoring système
-- =========================================

CREATE TABLE IF NOT EXISTS metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cpu_usage FLOAT NOT NULL,
    ram_usage FLOAT NOT NULL,
    disk_usage FLOAT NOT NULL,
    load_average FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- Historique des événements
-- =========================================

CREATE TABLE IF NOT EXISTS events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    ip VARCHAR(45),
    message TEXT,
    severity VARCHAR(20),
    action VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- Historique des bannissements
-- =========================================

CREATE TABLE IF NOT EXISTS bans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip VARCHAR(45) NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



