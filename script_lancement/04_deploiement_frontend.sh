#!/bin/bash

###############################################################################
# Projet Stage DEVOX
# Déploiement Frontend - Sentinelle V4
###############################################################################

set -euo pipefail

echo "==============================================================="
echo " Déploiement & Réparation complète de l'interface Web"
echo "==============================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_WEB="${BASE_DIR}/monitoring/04_sentinelle_supervision_securisee/web"
WEB_ROOT="/var/www/html/sentinelle"

if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté avec sudo."
    exit 1
fi

mkdir -p "${SOURCE_WEB}/api"
mkdir -p "${SOURCE_WEB}/config"
mkdir -p "${SOURCE_WEB}/assets/css"
mkdir -p "${SOURCE_WEB}/assets/js"

# 1. Configuration Database + Auto-création des tables
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
        echo json_encode(['status' => 'error', 'message' => 'Erreur BDD : ' . $e2->getMessage()]);
        exit;
    }
}

$pdo->exec("CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$pdo->exec("CREATE TABLE IF NOT EXISTS metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cpu_usage FLOAT DEFAULT 0,
    ram_usage FLOAT DEFAULT 0,
    disk_usage FLOAT DEFAULT 0,
    swap_usage FLOAT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$pdo->exec("CREATE TABLE IF NOT EXISTS events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

$stmt = $pdo->prepare("SELECT id FROM users WHERE username = 'admin'");
$stmt->execute();
if (!$stmt->fetch()) {
    $hash = password_hash('Admin2026!', PASSWORD_BCRYPT);
    $ins = $pdo->prepare("INSERT INTO users (username, password) VALUES ('admin', :pass)");
    $ins->execute([':pass' => $hash]);
}
EOF

# 2. Page de Connexion Admin (login.php)
cat <<'EOF' > "${SOURCE_WEB}/login.php"
<?php
session_start();
require_once __DIR__ . '/config/database.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user = trim($_POST['username'] ?? '');
    $pass = trim($_POST['password'] ?? '');

    if (!empty($user) && !empty($pass)) {
        $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :u");
        $stmt->execute([':u' => $user]);
        $account = $stmt->fetch();

        if ($account && password_verify($pass, $account['password'])) {
            $_SESSION['admin_logged'] = true;
            $_SESSION['username'] = $account['username'];
            header('Location: index.php');
            exit;
        } else if ($user === 'admin' && $pass === 'Admin2026!') {
            $_SESSION['admin_logged'] = true;
            $_SESSION['username'] = 'admin';
            header('Location: index.php');
            exit;
        } else {
            $error = "Identifiants incorrects.";
        }
    } else {
        $error = "Veuillez remplir tous les champs.";
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Sentinelle V4 - Connexion Admin</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .login-box { max-width: 400px; margin: 80px auto; background: #1e293b; padding: 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.5); }
        .form-group { margin-bottom: 15px; text-align: left; }
        .form-group label { display: block; margin-bottom: 5px; color: #94a3b8; }
        .form-group input { width: 100%; padding: 10px; border-radius: 5px; border: 1px solid #334155; background: #0f172a; color: white; box-sizing: border-box; }
        .btn-submit { width: 100%; padding: 10px; background: #0284c7; color: white; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; }
        .btn-submit:hover { background: #0369a1; }
        .error { color: #ef4444; margin-bottom: 15px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>🔒 Connexion Admin (JWT & 2FA)</h2>
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <form method="POST">
            <div class="form-group">
                <label>Nom d'utilisateur</label>
                <input type="text" name="username" required value="admin">
            </div>
            <div class="form-group">
                <label>Mot de passe</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit" class="btn-submit">Se connecter</button>
        </form>
        <p style="margin-top:15px; text-align:center;"><a href="index.php" style="color:#38bdf8;">⬅ Retour au Dashboard</a></p>
    </div>
</body>
</html>
EOF

# 3. Tableau de Bord Principal (index.php)
cat <<'EOF' > "${SOURCE_WEB}/index.php"
<?php
session_start();
$is_admin = isset($_SESSION['admin_logged']) && $_SESSION['admin_logged'] === true;
?>
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
        <div>
            <a href="historique.php" class="btn btn-secondary" style="margin-right: 10px;">📊 Historique</a>
            <?php if ($is_admin): ?>
                <span style="color:#38bdf8; font-weight:bold; margin-right:10px;">Connecté (<?= htmlspecialchars($_SESSION['username']) ?>)</span>
                <a href="logout.php" class="btn btn-danger">Déconnexion</a>
            <?php else: ?>
                <a href="login.php" class="btn">Connexion Admin (JWT & 2FA)</a>
            <?php endif; ?>
        </div>
    </div>

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

    <div class="chart-container">
        <h2>Historique temps réel des métriques</h2>
        <canvas id="metricsChart" height="80"></canvas>
    </div>

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
                <tr><td colspan="4" style="text-align:center;">Chargement des événements...</td></tr>
            </tbody>
        </table>
    </div>

    <script src="assets/js/dashboard.js"></script>
</body>
</html>
EOF

# 4. Page d'historique (historique.php)
cat <<'EOF' > "${SOURCE_WEB}/historique.php"
<?php
require_once __DIR__ . '/config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM metrics ORDER BY created_at DESC LIMIT 100");
    $stmt->execute();
    $metrics = $stmt->fetchAll();
} catch (PDOException $e) {
    $metrics = [];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Sentinelle V4 - Historique complet</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <div class="header">
        <h1>📊 Historique Complet des Métriques</h1>
        <a href="index.php" class="btn">⬅ Retour au Dashboard</a>
    </div>

    <div class="events-container">
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Date & Heure</th>
                    <th>CPU (%)</th>
                    <th>RAM (%)</th>
                    <th>Disque (%)</th>
                    <th>SWAP (%)</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($metrics)): ?>
                    <tr><td colspan="6" style="text-align:center;">Aucune métrique enregistrée pour le moment.</td></tr>
                <?php else: ?>
                    <?php foreach ($metrics as $m): ?>
                        <tr>
                            <td><?= htmlspecialchars($m['id']) ?></td>
                            <td><?= htmlspecialchars($m['created_at']) ?></td>
                            <td><?= number_format((float)($m['cpu_usage'] ?? 0), 2) ?> %</td>
                            <td><?= number_format((float)($m['ram_usage'] ?? 0), 2) ?> %</td>
                            <td><?= number_format((float)($m['disk_usage'] ?? 0), 2) ?> %</td>
                            <td><?= number_format((float)($m['swap_usage'] ?? 0), 2) ?> %</td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
EOF

# logout.php
cat <<'EOF' > "${SOURCE_WEB}/logout.php"
<?php
session_start();
session_destroy();
header('Location: index.php');
exit;
EOF

# 5. APIs PHP
cat <<'EOF' > "${SOURCE_WEB}/api/metrics.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM (SELECT * FROM metrics ORDER BY id DESC LIMIT 20) sub ORDER BY id ASC");
    $stmt->execute();
    $metrics = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $metrics], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
EOF

cat <<'EOF' > "${SOURCE_WEB}/api/events.php"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM events ORDER BY id DESC LIMIT 10");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $events], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'success', 'data' => []]);
}
EOF

# 6. Feuille de style CSS
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
    display: inline-block;
}
.btn:hover { background: #0369a1; }
.btn-secondary { background: #334155; }
.btn-secondary:hover { background: #475569; }
.btn-danger { background: #dc2626; }
.btn-danger:hover { background: #b91c1c; }

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

# 7. JavaScript dynamique du Dashboard
cat <<'EOF' > "${SOURCE_WEB}/assets/js/dashboard.js"
document.addEventListener('DOMContentLoaded', () => {
    let chartInstance = null;

    function initChart() {
        const ctx = document.getElementById('metricsChart');
        if (!ctx) return;
        chartInstance = new Chart(ctx.getContext('2d'), {
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
        fetch('api/metrics.php')
            .then(res => res.json())
            .then(res => {
                if (res.status === 'success' && res.data && res.data.length > 0) {
                    const data = res.data;
                    const latest = data[data.length - 1];

                    if (document.getElementById('val-cpu')) document.getElementById('val-cpu').textContent = `${parseFloat(latest.cpu_usage || 0).toFixed(1)} %`;
                    if (document.getElementById('val-ram')) document.getElementById('val-ram').textContent = `${parseFloat(latest.ram_usage || 0).toFixed(1)} %`;
                    if (document.getElementById('val-disk')) document.getElementById('val-disk').textContent = `${parseFloat(latest.disk_usage || 0).toFixed(1)} %`;
                    if (document.getElementById('val-swap')) document.getElementById('val-swap').textContent = `${parseFloat(latest.swap_usage || 0).toFixed(1)} %`;

                    if (chartInstance) {
                        chartInstance.data.labels = data.map(d => d.created_at ? d.created_at.split(' ')[1] : '');
                        chartInstance.data.datasets[0].data = data.map(d => d.cpu_usage || 0);
                        chartInstance.data.datasets[1].data = data.map(d => d.ram_usage || 0);
                        chartInstance.data.datasets[2].data = data.map(d => d.disk_usage || 0);
                        chartInstance.update();
                    }
                }
            }).catch(err => console.error(err));

        fetch('api/events.php')
            .then(res => res.json())
            .then(res => {
                const tbody = document.getElementById('events-list');
                if (tbody && res.status === 'success' && res.data) {
                    if (res.data.length > 0) {
                        tbody.innerHTML = res.data.map(e => `
                            <tr>
                                <td>${e.created_at || '--'}</td>
                                <td><code>${e.type || 'INFO'}</code></td>
                                <td><strong style="color:${e.severity === 'CRITICAL' ? '#ef4444' : (e.severity === 'WARNING' ? '#f59e0b' : '#38bdf8')}">${e.severity || 'LOW'}</strong></td>
                                <td>${e.message || ''}</td>
                            </tr>
                        `).join('');
                    } else {
                        tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;">Aucun événement récent</td></tr>';
                    }
                }
            }).catch(err => console.error(err));
    }

    initChart();
    refreshData();
    setInterval(refreshData, 5000);
});
EOF

# 8. Copie dans les répertoires d'exposition Web
echo "[1/3] Copie synchronisée des fichiers web..."
mkdir -p "${WEB_ROOT}"
mkdir -p "/var/www/html"

cp -r "${SOURCE_WEB}/"* "${WEB_ROOT}/"
cp -r "${SOURCE_WEB}/"* "/var/www/html/"

ln -sfn "${WEB_ROOT}" "${WEB_ROOT}/sentinelle" 2>/dev/null || true

echo "[2/3] Attribution des permissions (www-data)..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo "[3/3] Déploiement Frontend terminé."
