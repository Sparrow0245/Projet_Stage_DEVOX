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
            <?php if ($is_admin): ?>
                <span style="color:#38bdf8; font-weight:bold; margin-right:10px;">Connecté (<?= htmlspecialchars($_SESSION['username']) ?>)</span>
                <a href="logout.php" class="btn btn-danger">Déconnexion</a>
            <?php else: ?>
                <a href="login.php" class="btn">Connexion Admin</a>
            <?php endif; ?>
        </div>
    </div>

    <div class="cards-grid">
        <div class="card"><h3>CPU</h3><div class="value" id="val-cpu">-- %</div></div>
        <div class="card"><h3>RAM</h3><div class="value" id="val-ram">-- %</div></div>
        <div class="card"><h3>Disque</h3><div class="value" id="val-disk">-- %</div></div>
        <div class="card"><h3>SWAP</h3><div class="value" id="val-swap">-- %</div></div>
    </div>

    <div class="chart-container">
        <h2>Historique temps réel des métriques</h2>
        <canvas id="metricsChart" height="80"></canvas>
    </div>

    <script>
    document.addEventListener('DOMContentLoaded', () => {
        let chartInstance = null;
        const ctx = document.getElementById('metricsChart');
        if (ctx) {
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

                        if (document.getElementById('val-cpu')) document.getElementById('val-cpu').textContent = `${parseFloat(latest.cpu_usage).toFixed(1)} %`;
                        if (document.getElementById('val-ram')) document.getElementById('val-ram').textContent = `${parseFloat(latest.ram_usage).toFixed(1)} %`;
                        if (document.getElementById('val-disk')) document.getElementById('val-disk').textContent = `${parseFloat(latest.disk_usage).toFixed(1)} %`;
                        if (document.getElementById('val-swap')) document.getElementById('val-swap').textContent = `${parseFloat(latest.swap_usage || 0).toFixed(1)} %`;

                        if (chartInstance) {
                            chartInstance.data.labels = data.map(d => d.created_at ? d.created_at.split(' ')[1] : '');
                            chartInstance.data.datasets[0].data = data.map(d => d.cpu_usage);
                            chartInstance.data.datasets[1].data = data.map(d => d.ram_usage);
                            chartInstance.data.datasets[2].data = data.map(d => d.disk_usage);
                            chartInstance.update();
                        }
                    }
                }).catch(err => console.error(err));
        }

        refreshData();
        setInterval(refreshData, 5000);
    });
    </script>
</body>
</html>
