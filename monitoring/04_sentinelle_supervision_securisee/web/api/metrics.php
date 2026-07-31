<?php
/**
 * Sentinelle V4 - Endpoint API des métriques
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/api/metrics.php
 */

header('Content-Type: application/json');
require_once __DIR__ . '/../db.php';

// Récupération des 20 dernières métriques système
$stmtMetrics = $pdo->query("
    SELECT cpu_usage, ram_usage, disk_usage, swap_usage, network_rx_kb, network_tx_kb, created_at 
    FROM metrics 
    ORDER BY id DESC 
    LIMIT 20
");
$metrics = array_reverse($stmtMetrics->fetchAll());

// Récupération du statut des services systemd
$stmtServices = $pdo->query("
    SELECT service_name, status, last_check 
    FROM services_status
");
$services = $stmtServices->fetchAll();

// Récupération des derniers événements d'alerte
$stmtEvents = $pdo->query("
    SELECT event_type, severity, message, created_at 
    FROM events 
    ORDER BY id DESC 
    LIMIT 10
");
$events = $stmtEvents->fetchAll();

echo json_encode([
    'status'   => 'success',
    'timestamp' => date('Y-m-d H:i:s'),
    'metrics'  => $metrics,
    'services' => $services,
    'events'   => $events
]);
