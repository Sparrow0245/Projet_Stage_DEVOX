<?php
session_start();
require_once __DIR__ . '/config/database.php';

// Vérification accès Admin
if (!isset($_SESSION['admin_logged']) || $_SESSION['admin_logged'] !== true) {
    header('Location: login.php');
    exit;
}

// Récupération des données détaillées
try {
    $stmtMetrics = $pdo->query("SELECT * FROM metrics ORDER BY created_at DESC LIMIT 50");
    $metrics = $stmtMetrics->fetchAll();

    $stmtEvents = $pdo->query("SELECT * FROM events ORDER BY created_at DESC LIMIT 50");
    $events = $stmtEvents->fetchAll();
    
    $latestMetric = $metrics[0] ?? null;
} catch (PDOException $e) {
    $metrics = [];
    $events = [];
    $latestMetric = null;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Sentinelle V4 - Console Admin Détaillée</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0b0f19; color: #e2e8f0; margin: 0; padding: 20px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #0284c7; padding-bottom: 15px; margin-bottom: 25px; }
        .header h1 { margin: 0; color: #38bdf8; }
        .badge-admin { background: #166534; color: #4ade80; padding: 4px 12px; border-radius: 20px; font-weight: bold; font-size: 0.9rem; margin-right: 15px; }
        .btn { background: #0284c7; color: white; padding: 8px 16px; text-decoration: none; border-radius: 6px; font-weight: bold; }
        .btn-danger { background: #dc2626; }
        .grid-details { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .card-detail { background: #1e293b; padding: 18px; border-radius: 8px; border-left: 4px solid #38bdf8; }
        .card-detail h4 { margin: 0 0 8px 0; color: #94a3b8; font-size: 0.9rem; }
        .card-detail .val { font-size: 1.8rem; font-weight: bold; color: #f8fafc; }
        .panel { background: #1e293b; border-radius: 8px; padding: 20px; margin-bottom: 25px; }
        .panel h2 { color: #38bdf8; margin-top: 0; font-size: 1.2rem; border-bottom: 1px solid #334155; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #334155; font-size: 0.9rem; }
        th { background: #0f172a; color: #38bdf8; }
        tr:hover { background: #334155; }
        .severity-HIGH { color: #ef4444; font-weight: bold; }
        .severity-MEDIUM { color: #f59e0b; font-weight: bold; }
        .severity-LOW { color: #38bdf8; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛠️ Panneau d'Administration Détaillé</h1>
        <div>
            <span class="badge-admin">🛡️ Admin A2F Actif : <?= htmlspecialchars($_SESSION['username']) ?></span>
            <a href="index.php" class="btn">Vue Public</a>
            <a href="logout.php" class="btn btn-danger" style="margin-left:8px;">Déconnexion</a>
        </div>
    </div>

    <!-- Détails Système en direct -->
    <div class="grid-details">
        <div class="card-detail">
            <h4>Charge CPU Actuelle</h4>
            <div class="val"><?= isset($latestMetric['cpu_usage']) ? number_format((float)$latestMetric['cpu_usage'], 2) . ' %' : 'N/A' ?></div>
        </div>
        <div class="card-detail" style="border-left-color: #f59e0b;">
            <h4>Utilisation RAM</h4>
            <div class="val"><?= isset($latestMetric['ram_usage']) ? number_format((float)$latestMetric['ram_usage'], 2) . ' %' : 'N/A' ?></div>
        </div>
        <div class="card-detail" style="border-left-color: #ef4444;">
            <h4>Occupation Disque</h4>
            <div class="val"><?= isset($latestMetric['disk_usage']) ? number_format((float)$latestMetric['disk_usage'], 2) . ' %' : 'N/A' ?></div>
        </div>
        <div class="card-detail" style="border-left-color: #a855f7;">
            <h4>Espace SWAP</h4>
            <div class="val"><?= isset($latestMetric['swap_usage']) ? number_format((float)$latestMetric['swap_usage'], 2) . ' %' : 'N/A' ?></div>
        </div>
    </div>

    <!-- Table Événements Système -->
    <div class="panel">
        <h2>📋 Journal Détaillé des Événements & Alertes</h2>
        <table>
            <thead>
                <tr><th>ID</th><th>Horodatage</th><th>Type</th><th>Sévérité</th><th>Message Détaillé</th></tr>
            </thead>
            <tbody>
                <?php if (empty($events)): ?>
                    <tr><td colspan="5" style="text-align:center;">Aucun événement enregistré.</td></tr>
                <?php else: ?>
                    <?php foreach ($events as $e): ?>
                        <tr>
                            <td><?= htmlspecialchars($e['id']) ?></td>
                            <td><?= htmlspecialchars($e['created_at']) ?></td>
                            <td><code><?= htmlspecialchars($e['type']) ?></code></td>
                            <td class="severity-<?= htmlspecialchars($e['severity']) ?>"><?= htmlspecialchars($e['severity']) ?></td>
                            <td><?= htmlspecialchars($e['message']) ?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

    <!-- Table Historique Récent des Métriques -->
    <div class="panel">
        <h2>📊 50 Derniers Enregistrements de Métriques</h2>
        <table>
            <thead>
                <tr><th>ID</th><th>Date & Heure</th><th>CPU (%)</th><th>RAM (%)</th><th>Disque (%)</th><th>SWAP (%)</th></tr>
            </thead>
            <tbody>
                <?php if (empty($metrics)): ?>
                    <tr><td colspan="6" style="text-align:center;">Aucune donnée enregistrée.</td></tr>
                <?php else: ?>
                    <?php foreach ($metrics as $m): ?>
                        <tr>
                            <td><?= htmlspecialchars($m['id']) ?></td>
                            <td><?= htmlspecialchars($m['created_at']) ?></td>
                            <td><?= number_format((float)$m['cpu_usage'], 2) ?> %</td>
                            <td><?= number_format((float)$m['ram_usage'], 2) ?> %</td>
                            <td><?= number_format((float)$m['disk_usage'], 2) ?> %</td>
                            <td><?= number_format((float)($m['swap_usage'] ?? 0), 2) ?> %</td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
