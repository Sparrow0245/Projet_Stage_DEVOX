<?php
/**
 * Sentinelle V4 - Dashboard Public
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/index.php
 */
require_once __DIR__ . '/jwt_helper.php';

// Vérification si un administrateur est déjà connecté
$isLoggedIn = false;
if (isset($_COOKIE['sentinelle_jwt'])) {
    $isLoggedIn = (verifyJWT($_COOKIE['sentinelle_jwt']) !== false);
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Dashboard Public</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; }
        .card { background-color: #1e293b; border: 1px solid #334155; color: #fff; }
        .badge-active { background-color: #10b981; }
        .badge-inactive { background-color: #ef4444; }
        .badge-failed { background-color: #ef4444; }
    </style>
</head>
<body class="p-4">
    <div class="container-fluid">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1 class="h3 text-primary m-0">🛡️ Sentinelle V4 - Supervision</h1>
            <div>
                <?php if ($isLoggedIn): ?>
                    <a href="admin.php" class="btn btn-outline-success">Espace Administration</a>
                    <a href="logout.php" class="btn btn-outline-danger ms-2">Déconnexion</a>
                <?php else: ?>
                    <a href="login.php" class="btn btn-outline-primary">Connexion Admin (JWT & 2FA)</a>
                <?php endif; ?>
            </div>
        </div>

        <!-- Jauges des métriques principales -->
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card p-3 text-center">
                    <h6>CPU</h6>
                    <h3 id="cpu-val" class="text-info">-- %</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 text-center">
                    <h6>RAM</h6>
                    <h3 id="ram-val" class="text-warning">-- %</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 text-center">
                    <h6>Disque</h6>
                    <h3 id="disk-val" class="text-danger">-- %</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 text-center">
                    <h6>SWAP</h6>
                    <h3 id="swap-val" class="text-secondary">-- %</h3>
                </div>
            </div>
        </div>

        <!-- Graphique + Statut Services -->
        <div class="row g-3 mb-4">
            <div class="col-md-8">
                <div class="card p-3">
                    <h5 class="card-title mb-3">Historique des Métriques</h5>
                    <canvas id="metricsChart" height="120"></canvas>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3">
                    <h5 class="card-title mb-3">Statut des Services</h5>
                    <ul id="services-list" class="list-group list-group-flush"></ul>
                </div>
            </div>
        </div>

        <!-- Tableau des derniers événements -->
        <div class="card p-3">
            <h5 class="card-title mb-3">Dernières Alertes & Événements</h5>
            <div class="table-responsive">
                <table class="table table-dark table-striped mb-0">
                    <thead>
                        <tr>
                            <th>Horodatage</th>
                            <th>Type</th>
                            <th>Sévérité</th>
                            <th>Message</th>
                        </tr>
                    </thead>
                    <tbody id="events-table"></tbody>
                </table>
            </div>
        </div>
    </div>

    <script>
        const ctx = document.getElementById('metricsChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [
                    { label: 'CPU (%)', borderColor: '#0ea5e9', data: [], fill: false, tension: 0.2 },
                    { label: 'RAM (%)', borderColor: '#f59e0b', data: [], fill: false, tension: 0.2 },
                    { label: 'Disque (%)', borderColor: '#ef4444', data: [], fill: false, tension: 0.2 }
                ]
            },
            options: { responsive: true, scales: { y: { min: 0, max: 100 } } }
        });

        async function refreshDashboard() {
            try {
                const res = await fetch('api/metrics.php');
                const data = await res.json();

                if (data.metrics && data.metrics.length > 0) {
                    const last = data.metrics[data.metrics.length - 1];
                    document.getElementById('cpu-val').innerText = last.cpu_usage + ' %';
                    document.getElementById('ram-val').innerText = last.ram_usage + ' %';
                    document.getElementById('disk-val').innerText = last.disk_usage + ' %';
                    document.getElementById('swap-val').innerText = last.swap_usage + ' %';

                    chart.data.labels = data.metrics.map(m => m.created_at.split(' ')[1]);
                    chart.data.datasets[0].data = data.metrics.map(m => m.cpu_usage);
                    chart.data.datasets[1].data = data.metrics.map(m => m.ram_usage);
                    chart.data.datasets[2].data = data.metrics.map(m => m.disk_usage);
                    chart.update();
                }

                const sList = document.getElementById('services-list');
                sList.innerHTML = '';
                (data.services || []).forEach(s => {
                    const statusClass = (s.status === 'active' || s.status === 'running') ? 'badge-active' : 'badge-failed';
                    sList.innerHTML += `<li class="list-group-item bg-transparent text-white d-flex justify-content-between align-items-center">
                        ${s.service_name}
                        <span class="badge ${statusClass}">${(s.status || 'UNKNOWN').toUpperCase()}</span>
                    </li>`;
                });

                const eTable = document.getElementById('events-table');
                eTable.innerHTML = '';
                (data.events || []).forEach(e => {
                    const sevClass = e.severity === 'CRITICAL' ? 'bg-danger' : (e.severity === 'WARNING' ? 'bg-warning text-dark' : 'bg-info');
                    eTable.innerHTML += `<tr>
                        <td>${e.created_at || '-'}</td>
                        <td>${e.event_type || 'SYSTEM'}</td>
                        <td><span class="badge ${sevClass}">${e.severity || 'INFO'}</span></td>
                        <td>${e.message}</td>
                    </tr>`;
                });
            } catch (err) {
                console.error("Erreur d'actualisation API :", err);
            }
        }

        refreshDashboard();
        setInterval(refreshDashboard, 5000);
    </script>
</body>
</html>
