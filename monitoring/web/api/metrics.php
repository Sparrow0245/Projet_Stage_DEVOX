<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM metrics ORDER BY created_at DESC LIMIT 20");
    $stmt->execute();
    $metrics = array_reverse($stmt->fetchAll(PDO::FETCH_ASSOC));
    echo json_encode(['status' => 'success', 'data' => $metrics], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
