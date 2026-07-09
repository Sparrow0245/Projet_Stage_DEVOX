-- =====================================================
-- Base de données Sentinelle Monitoring
-- Projet Stage DEVOX
-- =====================================================


-- =====================================================
-- Sélection de la base
-- =====================================================

USE sentinelle;



-- =====================================================
-- Table des métriques système
-- Utilisée pour les graphiques du dashboard
-- =====================================================

CREATE TABLE IF NOT EXISTS metrics
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    cpu_usage FLOAT NOT NULL,

    ram_usage FLOAT NOT NULL,

    disk_usage FLOAT NOT NULL,

    load_average FLOAT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =====================================================
-- Table des événements détectés
-- Alertes générées par Sentinelle
-- =====================================================

CREATE TABLE IF NOT EXISTS events
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    type VARCHAR(50) NOT NULL,

    ip VARCHAR(45),

    message TEXT,

    severity ENUM(
        'INFO',
        'LOW',
        'MEDIUM',
        'HIGH',
        'CRITICAL'
    ) DEFAULT 'INFO',

    action VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =====================================================
-- Table des bannissements
-- Historique des IP bloquées
-- =====================================================

CREATE TABLE IF NOT EXISTS bans
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    ip VARCHAR(45) NOT NULL,

    reason TEXT,

    duration VARCHAR(50),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =====================================================
-- Table des utilisateurs du dashboard web
-- Connexion future à l'interface
-- =====================================================

CREATE TABLE IF NOT EXISTS users
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    username VARCHAR(50) NOT NULL UNIQUE,

    password VARCHAR(255) NOT NULL,

    role ENUM(
        'ADMIN',
        'USER'
    ) DEFAULT 'USER',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =====================================================
-- Données de test optionnelles
-- Permet de vérifier le dashboard
-- =====================================================

INSERT INTO events
(
    type,
    ip,
    message,
    severity,
    action
)
VALUES
(
    'SYSTEM',
    NULL,
    'Installation de Sentinelle terminée',
    'INFO',
    'INSTALL'
);



INSERT INTO metrics
(
    cpu_usage,
    ram_usage,
    disk_usage,
    load_average
)
VALUES
(
    0,
    0,
    0,
    0
);
