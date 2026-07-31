<?php
###############################################################################
# Projet Stage DEVOX
# Sentinelle V4 - API EndPoint Événements
###############################################################################

header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $stmt = $pdo->prepare("SELECT * FROM events ORDER BY created_at DESC LIMIT 50");
    $stmt->execute();
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['status' => 'success', 'data' => $events], JSON_PRETTY_PRINT);
} catch (PDOException $e) {
    // Si la table n'existe pas encore ou est vide, renvoie un tableau vide propre
    echo json_encode(['status' => 'success', 'data' => [], 'message' => 'Aucun événement enregistré']);
}
