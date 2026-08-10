#!/bin/bash

###############################################################################
# Sentinelle V4 - Entrypoint Web
###############################################################################

set -euo pipefail

CONFIG_DIR="/var/www/html/sentinelle/config"
DATABASE_CONFIG="${CONFIG_DIR}/database.php"

mkdir -p "${CONFIG_DIR}"

###############################################################################
# CONFIGURATION PHP MYSQL
###############################################################################

cat > "${DATABASE_CONFIG}" <<EOF
<?php

\$db_host = getenv('DB_HOST') ?: 'sentinelle-db';
\$db_port = getenv('DB_PORT') ?: '3306';
\$db_name = getenv('DB_NAME') ?: 'sentinelle';
\$db_user = getenv('DB_USER') ?: 'sentinelle';
\$db_pass = getenv('DB_PASSWORD') ?: '';

try {

    \$pdo = new PDO(
        "mysql:host={\$db_host};port={\$db_port};dbname={\$db_name};charset=utf8mb4",
        \$db_user,
        \$db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );

} catch (PDOException \$e) {

    header('Content-Type: application/json');

    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur de connexion à la base de données.'
    ]);

    exit;
}
EOF

chown www-data:www-data "${DATABASE_CONFIG}"

chmod 640 "${DATABASE_CONFIG}"

echo "==============================================================="
echo " Sentinelle V4 - Interface Web"
echo "==============================================================="

echo "[INFO] Base de données : ${DB_HOST}:${DB_PORT}"
echo "[INFO] Backend         : ${BACKEND_HOST}:${BACKEND_PORT}"
echo "[INFO] Apache          : port 80"

exec apache2-foreground
