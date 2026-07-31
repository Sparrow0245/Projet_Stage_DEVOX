#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement Frontend Sentinelle V4
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

echo "[INFO] Préparation de l'arborescence..."
mkdir -p "${SOURCE_WEB}/api"
mkdir -p "${SOURCE_WEB}/config"
mkdir -p "${SOURCE_WEB}/assets/css"
mkdir -p "${SOURCE_WEB}/assets/js"

# 1. Configuration Base de Données
cat <<'EOF' > "${SOURCE_WEB}/config/database.php"
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

# 2. EndPoint API Metrics
cat <<'EOF' > "${SOURCE_WEB}/api/metrics.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM metrics ORDER BY created_at DESC LIMIT 20");
    $stmt->execute();
    $metrics = array_reverse($stmt->fetchAll(PDO::FETCH_ASSOC));
    echo json_encode(['status' => 'success', 'data' => $metrics], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
EOF

# 3. EndPoint API Events
cat <<'EOF' > "${SOURCE_WEB}/api/events.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM events ORDER BY created_at DESC LIMIT 10");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $events], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'success', 'data' => []]);
}
EOF

# 4. Interface HTML Principal (index.php)
cat <<'EOF' > "${SOURCE_WEB}/index.php"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Supervision</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="header">
        <h1>🛡️ Sentinelle V4 - Supervision</h1>
        <a href="historique.php" class="btn">Voir l'historique complet</a>
    </div>

    <!-- Cartes de métriques -->
    <div class="cards-grid">
        <div class="card">
            <h3>CPU</h3>
            <div class="value" id="val-cpu">-- %</div>
        </div>
        <div class="card">
            <h3>RAM</h3>
            <div class="value" id="val-ram">-- %</div>
        </div>
        <div class="card">
            <h3>Disque</h3>
            <div class="value" id="val-disk">-- %</div>
        </div>
        <div class="card">
            <h3>SWAP</h3>
            <div class="value" id="val-swap">-- %</div>
        </div>
    </div>

    <!-- Graphique -->
    <div class="chart-container">
        <h2>Historique temps réel des métriques</h2>
        <canvas id="metricsChart" height="90"></canvas>
    </div>

    <!-- Tableau d'événements -->
    <div class="events-container">
        <h2>Dernières Alertes & Événements</h2>
        <table>
            <thead>
                <tr>
                    <th>Horodatage</th>
                    <th>Type</th>
                    <th>Sévérité</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody id="events-list">
                <tr><td colspan="4" style="text-align:center;">Chargement...</td></tr>
            </tbody>
        </table>
    </div>

    <script src="assets/js/dashboard.js"></script>
</body>
</html>
EOF

# 5. Feuille de style CSS moderne
cat <<'EOF' > "${SOURCE_WEB}/assets/css/style.css"
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: #0b0f19;
    color: #e2e8f0;
    margin: 0;
    padding: 20px;
}
.header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #1e293b;
    padding-bottom: 15px;
    margin-bottom: 25px;
}
.header h1 { margin: 0; color: #38bdf8; font-size: 1.8rem; }
.btn {
    background: #0284c7;
    color: white;
    padding: 8px 16px;
    text-decoration: none;
    border-radius: 6px;
    font-weight: bold;
}
.btn:hover { background: #0369a1; }
.cards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-bottom: 25px;
}
.card {
    background: #1e293b;
    border-radius: 8px;
    padding: 20px;
    text-align: center;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
}
.card h3 { margin: 0 0 10px 0; color: #94a3b8; font-size: 1rem; }
.card .value { font-size: 2rem; font-weight: bold; color: #38bdf8; }
.chart-container, .events-container {
    background: #1e293b;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 25px;
}
h2 { color: #f8fafc; font-size: 1.2rem; margin-top: 0; margin-bottom: 15px; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid #334155; }
th { background: #0f172a; color: #38bdf8; }
tr:hover { background: #334155; }
EOF

# 6. JavaScript dynamique (dashboard.js)
cat <<'EOF' > "${SOURCE_WEB}/assets/js/dashboard.js"
document.addEventListener('DOMContentLoaded', () => {
    let chartInstance = null;

    function initChart() {
        const ctx = document.getElementById('metricsChart').getContext('2d');
        chartInstance = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [
                    { label: 'CPU (%)', borderColor: '#38bdf8', data: [], fill: false, tension: 0.3 },
                    { label: 'RAM (%)', borderColor: '#f59e0b', data: [], fill: false, tension: 0.3 },
                    { label: 'Disque (%)', borderColor: '#ef4444', data: [], fill: false, tension: 0.3 }
                ]
            },
            options: {
                responsive: true,
                scales: {
                    y: { beginAtZero: true, max: 100, grid: { color: '#334155' } },
                    x: { grid: { color: '#334155' } }
                }
            }
        });
    }

    function refreshData() {
        // Métriques
        fetch('api/metrics.php')
            .then(res => res.json())
            .then(res => {
                if (res.status === 'success' && res.data && res.data.length > 0) {
                    const data = res.data;
                    const latest = data[data.length - 1];

                    document.getElementById('val-cpu').textContent = `${parseFloat(latest.cpu_usage).toFixed(1)} %`;
                    document.getElementById('val-ram').textContent = `${parseFloat(latest.ram_usage).toFixed(1)} %`;
                    document.getElementById('val-disk').textContent = `${parseFloat(latest.disk_usage).toFixed(1)} %`;
                    document.getElementById('val-swap').textContent = `${parseFloat(latest.swap_usage || 0).toFixed(1)} %`;

                    if (chartInstance) {
                        chartInstance.data.labels = data.map(d => d.created_at ? d.created_at.split(' ')[1] : '');
                        chartInstance.data.datasets[0].data = data.map(d => d.cpu_usage);
                        chartInstance.data.datasets[1].data = data.map(d => d.ram_usage);
                        chartInstance.data.datasets[2].data = data.map(d => d.disk_usage);
                        chartInstance.update();
                    }
                }
            }).catch(err => console.error(err));

        // Événements
        fetch('api/events.php')
            .then(res => res.json())
            .then(res => {
                const tbody = document.getElementById('events-list');
                if (res.status === 'success' && res.data && res.data.length > 0) {
                    tbody.innerHTML = res.data.map(e => `
                        <tr>
                            <td>${e.created_at || '--'}</td>
                            <td>${e.type || 'INFO'}</td>
                            <td><strong>${e.severity || 'LOW'}</strong></td>
                            <td>${e.message || ''}</td>
                        </tr>
                    `).join('');
                } else {
                    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;">Aucun événement récent</td></tr>';
                }
            }).catch(err => console.error(err));
    }

    initChart();
    refreshData();
    setInterval(refreshData, 5000);
});
EOF

echo "[1/3] Copie des fichiers vers la racine web..."
mkdir -p "${WEB_ROOT}"
cp -r "${SOURCE_WEB}/"* "${WEB_ROOT}/"

# Copie également dans /var/www/html/ si l'accès se fait par subpath
cp -r "${SOURCE_WEB}/"* "/var/www/html/" 2>/dev/null || true

echo "[2/3] Attribution des permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "[3/3] Redémarrage Apache..."
systemctl reload apache2 || systemctl restart apache2

echo "==============================================================="
echo " Déploiement Frontend terminé avec succès !"
echo "==============================================================="
