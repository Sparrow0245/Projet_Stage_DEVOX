<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    // Récupère les 20 dernières métriques dans l'ordre chronologique
    $stmt = $pdo->prepare("SELECT * FROM (SELECT * FROM metrics ORDER BY id DESC LIMIT 20) sub ORDER BY id ASC");
    $stmt->execute();
    $metrics = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $metrics], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => 'Erreur de récupération des métriques']);
}
