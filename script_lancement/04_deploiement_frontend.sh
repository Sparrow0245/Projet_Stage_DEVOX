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

echo "[INFO] Vérification et préparation des dossiers web source"
mkdir -p "${SOURCE_WEB}"
mkdir -p "${SOURCE_WEB}/api"
mkdir -p "${SOURCE_WEB}/config"
mkdir -p "${SOURCE_WEB}/assets/css"
mkdir -p "${SOURCE_WEB}/assets/js"

# 1. Auto-génération de historique.php si absent
HISTORIQUE_SRC="${SOURCE_WEB}/historique.php"
if [[ ! -f "${HISTORIQUE_SRC}" ]]; then
    echo "[INFO] Création automatique de historique.php dans le dossier source..."
    cat <<'EOF' > "${HISTORIQUE_SRC}"
<?php
###############################################################################
# Projet Stage DEVOX
# Sentinelle V4 - Page d'historique de supervision
###############################################################################

require_once __DIR__ . '/config/database.php';

$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
if ($limit <= 0 || $limit > 1000) { $limit = 100; }

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
        body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 1200px; margin: 0 auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #007bff; padding-bottom: 10px; margin-bottom: 20px; }
        .header h1 { margin: 0; color: #007bff; }
        .nav-links a { text-decoration: none; color: #007bff; font-weight: bold; margin-left: 15px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #007bff; color: white; }
        tr:hover { background-color: #f1f1f1; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Historique de Supervision - Sentinelle V4</h1>
            <div class="nav-links">
                <a href="index.php">⬅ Retour au Tableau de bord</a>
                <a href="historique.php?limit=50">50 derniers</a>
                <a href="historique.php?limit=200">200 derniers</a>
            </div>
        </div>
        <h2>Derniers relevés enregistrés (<?= count($metrics) ?>)</h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Date & Heure</th>
                    <th>Utilisation CPU (%)</th>
                    <th>Utilisation RAM (%)</th>
                    <th>Utilisation Disque (%)</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($metrics)): ?>
                    <tr><td colspan="5" style="text-align: center;">Aucune métrique trouvée dans la base de données.</td></tr>
                <?php else: ?>
                    <?php foreach ($metrics as $m): ?>
                        <tr>
                            <td><?= htmlspecialchars($m['id']) ?></td>
                            <td><?= htmlspecialchars($m['created_at']) ?></td>
                            <td><?= number_format((float)$m['cpu_usage'], 2) ?> %</td>
                            <td><?= number_format((float)$m['ram_usage'], 2) ?> %</td>
                            <td><?= number_format((float)$m['disk_usage'], 2) ?> %</td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>
EOF
    echo "[OK] Fichier historique.php prêt"
fi

# 2. Auto-génération de api/events.php si absent
EVENTS_SRC="${SOURCE_WEB}/api/events.php"
if [[ ! -f "${EVENTS_SRC}" ]]; then
    echo "[INFO] Création automatique de api/events.php dans le dossier source..."
    cat <<'EOF' > "${EVENTS_SRC}"
<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM events ORDER BY created_at DESC LIMIT 50");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $events], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'success', 'data' => [], 'message' => 'Aucun événement enregistré']);
}
EOF
    echo "[OK] Fichier api/events.php prêt"
fi

# 3. Auto-génération de config/database.php si absent
DB_CONF_SRC="${SOURCE_WEB}/config/database.php"
if [[ ! -f "${DB_CONF_SRC}" ]]; then
    echo "[INFO] Création automatique de config/database.php..."
    cat <<'EOF' > "${DB_CONF_SRC}"
<?php
$db_host = 'localhost';
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
    header('HTTP/1.1 500 Internal Server Error');
    echo json_encode(['status' => 'error', 'message' => 'Erreur de connexion BDD']);
    exit;
}
EOF
    echo "[OK] Fichier config/database.php prêt"
fi

# 4. Auto-génération des assets CSS & JS si absents
CSS_SRC="${SOURCE_WEB}/assets/css/style.css"
if [[ ! -f "${CSS_SRC}" ]]; then
    echo "/* Styles Sentinelle V4 */ body { font-family: sans-serif; background: #f4f6f9; }" > "${CSS_SRC}"
fi

JS_SRC="${SOURCE_WEB}/assets/js/dashboard.js"
if [[ ! -f "${JS_SRC}" ]]; then
    echo "// Scripts Dashboard Sentinelle V4" > "${JS_SRC}"
fi

echo
echo "[1/5] Création répertoire web"
mkdir -p "${WEB_ROOT}"

if [[ -d "${WEB_ROOT}" ]] && [[ "$(ls -A ${WEB_ROOT})" ]]; then
    echo "[INFO] Sauvegarde ancienne version"
    BACKUP="/var/backups/sentinelle_web_$(date +%Y%m%d_%H%M%S)"
    mkdir -p /var/backups
    cp -r "${WEB_ROOT}" "${BACKUP}"
    echo "[OK] Sauvegarde créée : ${BACKUP}"
fi

echo
echo "[2/5] Copie fichiers interface"
cp -r "${SOURCE_WEB}/"* "${WEB_ROOT}/"

echo
echo "[3/5] Configuration permissions"
chown -R www-data:www-data "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

echo
echo "[4/5] Vérification fichiers principaux"
FILES_REQUIRED=(
    "index.php"
    "historique.php"
    "api/metrics.php"
    "api/events.php"
    "config/database.php"
    "assets/css/style.css"
    "assets/js/dashboard.js"
)

for FILE in "${FILES_REQUIRED[@]}"; do
    if [[ -f "${WEB_ROOT}/${FILE}" ]]; then
        echo "[OK] ${FILE}"
    else
        echo "[ERREUR] Fichier manquant : ${FILE}"
        exit 1
    fi
done

echo
echo "[5/5] Vérification PHP"
php -v > /dev/null
systemctl reload apache2 || true

echo
echo "==============================================================="
echo " Interface Web installée dans ${WEB_ROOT}"
echo "==============================================================="
