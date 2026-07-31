<?php
/**
 * Sentinelle V4 - Panneau d'Administration Securisé
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/admin.php
 */

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/jwt_helper.php';

// Verification stricte de l'authentification JWT via Cookie
if (!isset($_COOKIE['sentinelle_jwt'])) {
    header('Location: login.php');
    exit;
}

$userData = verifyJWT($_COOKIE['sentinelle_jwt']);
if (!$userData) {
    // Si le token est invalide ou expiré, déconnexion et nettoyage
    header('Location: logout.php');
    exit;
}

// Récupération des statistiques globales pour l'administrateur
$totalMetricsCount = $pdo->query("SELECT COUNT(*) FROM metrics")->fetchColumn();
$totalEventsCount   = $pdo->query("SELECT COUNT(*) FROM events")->fetchColumn();
$servicesCount     = $pdo->query("SELECT COUNT(*) FROM services_status")->fetchColumn();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Panneau d'Administration</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #0f172a; color: #f8fafc; font-family: system-ui, -apple-system, sans-serif; }
        .card { background-color: #1e293b; border: 1px solid #334155; color: #fff; }
    </style>
</head>
<body class="p-4">
    <div class="container">
        <div class="d-flex justify-content-between align-items-center mb-4 pb-3 border-bottom border-secondary">
            <div>
                <h1 class="h3 text-warning m-0">⚙️ Espace Administration Sentinelle</h1>
                <small class="text-muted">Connecté en tant que : <strong><?= htmlspecialchars($userData['username']) ?></strong> (Rôle: <?= htmlspecialchars($userData['role']) ?>)</small>
            </div>
            <div>
                <a href="index.php" class="btn btn-outline-light me-2">Voir le Dashboard</a>
                <a href="logout.php" class="btn btn-danger">Déconnexion</a>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-md-4">
                <div class="card p-3 text-center">
                    <h5 class="text-muted">Entrées Métriques BDD</h5>
                    <h2 class="text-primary"><?= number_format($totalMetricsCount) ?></h2>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 text-center">
                    <h5 class="text-muted">Services Supervisés</h5>
                    <h2 class="text-success"><?= $servicesCount ?></h2>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 text-center">
                    <h5 class="text-muted">Événements Enregistrés</h5>
                    <h2 class="text-warning"><?= number_format($totalEventsCount) ?></h2>
                </div>
            </div>
        </div>

        <div class="card p-4">
            <h4 class="card-title text-info mb-3">Informations de Session JWT & 2FA</h4>
            <ul class="list-group list-group-flush bg-transparent">
                <li class="list-group-item bg-transparent text-white border-secondary">
                    <strong>ID Utilisateur (Subject) :</strong> <?= htmlspecialchars($userData['sub'] ?? 'N/A') ?>
                </li>
                <li class="list-group-item bg-transparent text-white border-secondary">
                    <strong>Horodatage d'émission (iat) :</strong> <?= date('Y-m-d H:i:s', $userData['iat'] ?? time()) ?>
                </li>
                <li class="list-group-item bg-transparent text-white border-secondary">
                    <strong>Expiration du Jeton (exp) :</strong> <?= date('Y-m-d H:i:s', $userData['exp'] ?? time()) ?>
                </li>
            </ul>
        </div>
    </div>
</body>
</html>
