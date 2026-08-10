#!/bin/bash

###############################################################################
# SENTINELLE V4
# Entrypoint Apache/PHP
###############################################################################

set -euo pipefail

echo "==============================================================="
echo "       SENTINELLE V4 - WEB"
echo "==============================================================="

CONFIG_DIR="/var/www/html/sentinelle/config"

mkdir -p "${CONFIG_DIR}"

###############################################################################
# GENERATION DE LA CONFIGURATION BDD
###############################################################################

cat > "${CONFIG_DIR}/database.php" <<'PHP'
<?php

$db_host = getenv('DB_HOST') ?: 'sentinelle-db';
$db_port = getenv('DB_PORT') ?: '3306';
$db_name = getenv('DB_NAME') ?: 'sentinelle';
$db_user = getenv('DB_USER') ?: 'sentinelle';
$db_pass = getenv('DB_PASSWORD') ?: '';

try {

    $pdo = new PDO(
        "mysql:host={$db_host};port={$db_port};dbname={$db_name};charset=utf8mb4",
        $db_user,
        $db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );

} catch (PDOException $e) {

    http_response_code(500);

    header('Content-Type: application/json');

    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur de connexion à la base de données.'
    ]);

    exit;
}
PHP

###############################################################################
# COMPATIBILITE AVEC db.php
###############################################################################

cat > "/var/www/html/sentinelle/db.php" <<'PHP'
<?php

$host = getenv('DB_HOST') ?: 'sentinelle-db';
$port = getenv('DB_PORT') ?: '3306';
$db = getenv('DB_NAME') ?: 'sentinelle';
$user = getenv('DB_USER') ?: 'sentinelle';
$pass = getenv('DB_PASSWORD') ?: '';

$charset = 'utf8mb4';

$dsn = "mysql:host={$host};port={$port};dbname={$db};charset={$charset}";

$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
];

try {

    $pdo = new PDO($dsn, $user, $pass, $options);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        'error' => 'Erreur de connexion à la base de données.'
    ]);

    exit;
}
PHP

###############################################################################
# PERMISSIONS
###############################################################################

chown -R www-data:www-data /var/www/html/sentinelle

chmod 640 \
    /var/www/html/sentinelle/config/database.php \
    /var/www/html/sentinelle/db.php

echo "[OK] Configuration PHP générée."

###############################################################################
# DEMARRAGE APACHE
###############################################################################

exec apache2-foreground
