#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement interface Web Sentinelle
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Déploiement interface Web Sentinelle"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_WEB="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/web"
WEB_ROOT="/var/www/html/sentinelle"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

echo "[INFO] Préparation des répertoires Web source..."
mkdir -p "${SOURCE_WEB}/api"
mkdir -p "${SOURCE_WEB}/config"
mkdir -p "${SOURCE_WEB}/assets/css"
mkdir -p "${SOURCE_WEB}/assets/js"

# 1. Config BDD
DB_CONF_SRC="${SOURCE_WEB}/config/database.php"
cat <<'EOF' > "${DB_CONF_SRC}"
<?php
$db_host = '127.0.0.1';
$db_name = 'sentinelle';
$db_user = 'sentinelle';
$db_pass = 'SentinelleSecurePass2026!';

try {
    $pdo = new PDO("mysql:host={$db_host};dbname={$db_name};charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    try {
        $pdo = new PDO("mysql:host=localhost;dbname={$db_name};charset=utf8mb4", $db_user, $db_pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    } catch (PDOException $e2) {
        header('Content-Type: application/json');
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Erreur BDD']);
        exit;
    }
}
EOF

# 2. API Metrics
cat <<'EOF' > "${SOURCE_WEB}/api/metrics.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM metrics ORDER BY created_at DESC LIMIT 50");
    $stmt->execute();
    $metrics = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $metrics], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'success', 'data' => []]);
}
EOF

# 3. API Events
cat <<'EOF' > "${SOURCE_WEB}/api/events.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM events ORDER BY created_at DESC LIMIT 50");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $events], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'success', 'data' => []]);
}
EOF

# 4. JS Dashboard (Dynamique)
cat <<'EOF' > "${SOURCE_WEB}/assets/js/dashboard.js"
document.addEventListener('DOMContentLoaded', () => {
    function updateDashboard() {
        fetch('api/metrics.php')
            .then(r => r.json())
            .then(res => {
                if (res.status === 'success' && res.data && res.data.length > 0) {
                    const latest = res.data[0];
                    const cards = document.querySelectorAll('div, .card');
                    cards.forEach(c => {
                        const txt = c.textContent.trim().toUpperCase();
                        if (txt.startsWith('CPU')) updateVal(c, latest.cpu_usage);
                        else if (txt.startsWith('RAM')) updateVal(c, latest.ram_usage);
                        else if (txt.startsWith('DISQUE')) updateVal(c, latest.disk_usage);
                        else if (txt.startsWith('SWAP')) updateVal(c, latest.swap_usage || 0);
                    });
                }
            }).catch(e => console.error(e));
    }

    function updateVal(container, val) {
        const target = container.querySelector('h2, span, p, div') || container;
        if (target && val !== undefined) {
            target.childNodes.forEach(n => {
                if (n.nodeType === Node.TEXT_NODE && n.nodeValue.includes('%')) {
                    n.nodeValue = ` ${parseFloat(val).toFixed(1)} %`;
                }
            });
        }
    }

    updateDashboard();
    setInterval(updateDashboard, 5000);
});
EOF

echo "[1/4] Copie des fichiers web vers ${WEB_ROOT}"
mkdir -p "${WEB_ROOT}"
cp -r "${SOURCE_WEB}/"* "${WEB_ROOT}/"

echo "[2/4] Configuration des permissions"
chown -R www-data:www-data "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

echo "[3/4] Test de syntaxe PHP"
php -v > /dev/null
systemctl reload apache2 || true

echo "==============================================================="
echo " Déploiement Frontend OK"
echo "==============================================================="
