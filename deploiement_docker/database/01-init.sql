###############################################################################
-- Sentinelle V4 - Initialisation de la base
###############################################################################

USE sentinelle;

CREATE TABLE IF NOT EXISTS hosts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    status ENUM('online', 'offline', 'warning') DEFAULT 'online',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS metrics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL DEFAULT 1,
    cpu_usage DECIMAL(5,2) NOT NULL,
    ram_usage DECIMAL(5,2) NOT NULL,
    disk_usage DECIMAL(5,2) NOT NULL,
    swap_usage DECIMAL(5,2) DEFAULT 0.00,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_metrics_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS services_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL DEFAULT 1,
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_host_service (host_id, service_name),
    CONSTRAINT fk_services_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS events (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    host_id INT NOT NULL DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'INFO',
    status VARCHAR(50) DEFAULT 'active',
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_events_host
        FOREIGN KEY (host_id)
        REFERENCES hosts(id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    totp_secret VARCHAR(64) DEFAULT NULL,
    role ENUM('admin', 'viewer') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

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

CREATE INDEX idx_metrics_host_timestamp
    ON metrics(host_id, timestamp);

CREATE INDEX idx_events_host_created
    ON events(host_id, created_at);
