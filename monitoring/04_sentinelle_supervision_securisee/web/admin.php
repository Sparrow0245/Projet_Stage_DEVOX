<?php
/**
 * Sentinelle V4 - Console Administrateur Protégée par JWT
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/admin.php
 */

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/jwt_helper.php';

$jwtToken = $_COOKIE['sentinelle_jwt'] ?? '';

// Support de l'en-tête HTTP Authorization Bearer
if (empty($jwtToken) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
    if (preg_match('/Bearer\s(\S+)/', $_SERVER['HTTP_AUTHORIZATION'], $matches)) {
        $jwtToken = $matches[1];
    }
}

$user = verifyJWT($jwtToken);

if (!$user || $user['role'] !== 'ADMIN') {
    // Redirection si le token JWT est absent, invalide ou expiré
    header('Location: login.php');
    exit;
}

// Récupération des services systemd
$stmtServices = $pdo->query("SELECT service_name, status, last_check FROM services_status ORDER BY service_name ASC");
$services = $stmtServices->fetchAll();

// Récupération des alertes
$stmtEvents = $pdo->query("SELECT event_type, severity, message, created_at FROM events ORDER BY id DESC LIMIT 50");
$events = $stmtEvents->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Administration JWT</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <header class="navbar">
        <div class="brand">🛡️ Sentinelle V4 - Console Admin</div>
        <nav>
            <a href="index.php" class="btn-nav">Dashboard Public</a>
            <a href="logout.php" class="btn-nav danger">Déconnexion (<?= htmlspecialchars($user['username']) ?>)</a>
        </nav>
    </header>

    <main class="container">
        <div class="alert alert-info" style="background: #1e293b; padding: 1rem; border-radius: 6px; border: 1px solid #38bdf8; margin-bottom: 1.5rem;">
            <strong>Session Active JWT :</strong> Connecté en tant que <code><?= htmlspecialchars($user['username']) ?></code> (Rôle: <?= htmlspecialchars($user['role']) ?>)
        </div>

        <h2>État des Services Systemd</h2>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Service</th>
                    <th>Statut</th>
                    <th>Dernière vérification</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($services as $svc): ?>
                    <tr>
                        <td><strong><?= htmlspecialchars($svc['service_name']) ?></strong></td>
                        <td>
                            <span class="badge badge-<?= $svc['status'] === 'ACTIVE' ? 'success' : 'danger' ?>">
                                <?= htmlspecialchars($svc['status']) ?>
                            </span>
                        </td>
                        <td><?= htmlspecialchars($svc['last_check']) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>

        <h2>Journal des Événements & Alertes Sécurité</h2>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Horodatage</th>
                    <th>Type</th>
                    <th>Sévérité</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($events as $event): ?>
                    <tr>
                        <td><?= htmlspecialchars($event['created_at']) ?></td>
                        <td><code><?= htmlspecialchars($event['event_type']) ?></code></td>
                        <td>
                            <span class="badge badge-<?= strtolower($event['severity']) ?>">
                                <?= htmlspecialchars($event['severity']) ?>
                            </span>
                        </td>
                        <td><?= htmlspecialchars($event['message']) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </main>
</body>
</html>
