<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    // S'assurer que la table existe
    $pdo->exec("CREATE TABLE IF NOT EXISTS metrics (
        id INT AUTO_INCREMENT PRIMARY KEY,
        cpu_usage FLOAT DEFAULT 0,
        ram_usage FLOAT DEFAULT 0,
        disk_usage FLOAT DEFAULT 0,
        swap_usage FLOAT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    // Récupération des 20 derniers enregistrements
    $stmt = $pdo->prepare("SELECT * FROM (SELECT * FROM metrics ORDER BY id DESC LIMIT 20) sub ORDER BY id ASC");
    $stmt->execute();
    $metrics = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'status' => 'success',
        'count' => count($metrics),
        'data' => $metrics
    ], JSON_PRETTY_PRINT);

} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur BDD : ' . $e->getMessage()
    ]);
}
