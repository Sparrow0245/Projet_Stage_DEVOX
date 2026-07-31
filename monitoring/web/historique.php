<?php
###############################################################################
# Projet Stage DEVOX
# Sentinelle V4 - Page d'historique de supervision
###############################################################################

require_once __DIR__ . '/config/database.php';

// Récupération du filtre de limite (par défaut 100 enregistrements)
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
if ($limit <= 0 || $limit > 1000) {
    $limit = 100;
}

// Récupération des métriques historiques
try {
    $stmt = $pdo->prepare("SELECT id, cpu_usage, ram_usage, disk_usage, created_at FROM metrics ORDER BY created_at DESC LIMIT :limit");
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();
    $metrics = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error_message = "Erreur de lecture de l'historique : " . $e->getMessage();
    $metrics = [];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Historique des Métriques</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f6f9;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .header h1 {
            margin: 0;
            color: #007bff;
        }
        .nav-links a {
            text-decoration: none;
            color: #007bff;
            font-weight: bold;
            margin-left: 15px;
        }
        .nav-links a:hover {
            text-decoration: underline;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #007bff;
            color: white;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        .bg-success { background-color: #28a745; }
        .bg-warning { background-color: #ffc107; color: #212529; }
        .bg-danger { background-color: #dc3545; }
        .alert {
            padding: 15px;
            background-color: #f8d7da;
            color: #721c24;
            border-radius: 4px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Historique de Supervision - Sentinelle V4</h1>
            <div class="nav-links">
                <a href="index.php">⬅ Retour au Tableur de bord</a>
                <a href="historique.php?limit=50">50 derniers</a>
                <a href="historique.php?limit=200">200 derniers</a>
            </div>
        </div>

        <?php if (isset($error_message)): ?>
            <div class="alert"><?= htmlspecialchars($error_message) ?></div>
        <?php endif; ?>

        <h2>Derniers relevés enregistrés (<?= count($metrics) ?>)</h2>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Date & Heure</th>
                    <th>Utilisation CPU (%)</th>
                    <th>Utilisation RAM (%)</th>
                    <th>Utilisation Disque (%)</th>
                    <th>Statut global</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($metrics)): ?>
                    <tr>
                        <td colspan="6" style="text-align: center;">Aucune métrique trouvée dans la base de données.</td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($metrics as $m): ?>
                        <?php 
                            $cpu = (float)$m['cpu_usage'];
                            $ram = (float)$m['ram_usage'];
                            $disk = (float)$m['disk_usage'];
                            
                            $status = "OK";
                            $badge_class = "bg-success";

                            if ($cpu > 85 || $ram > 90 || $disk > 90) {
                                $status = "CRITIQUE";
                                $badge_class = "bg-danger";
                            } elseif ($cpu > 70 || $ram > 75 || $disk > 80) {
                                $status = "ATTENTION";
                                $badge_class = "bg-warning";
                            }
                        ?>
                        <tr>
                            <td><?= htmlspecialchars($m['id']) ?></td>
                            <td><?= htmlspecialchars($m['created_at']) ?></td>
                            <td><?= number_format($cpu, 2) ?> %</td>
                            <td><?= number_format($ram, 2) ?> %</td>
                            <td><?= number_format($disk, 2) ?> %</td>
                            <td><span class="badge <?= $badge_class ?>"><?= $status ?></span></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
