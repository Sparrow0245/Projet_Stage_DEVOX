<?php
###############################################################################
# Projet Stage DEVOX
# Sentinelle V4 - API EndPoint Événements
###############################################################################

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
