-- =========================================
-- Monitoring système
-- =========================================

CREATE TABLE IF NOT EXISTS metrics
(
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

CREATE TABLE IF NOT EXISTS events
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50),
    ip VARCHAR(45),
    message TEXT,
    severity VARCHAR(20),
    action VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- Historique bannissements
-- =========================================

CREATE TABLE IF NOT EXISTS bans
(
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip VARCHAR(45),
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
