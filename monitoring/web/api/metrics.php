<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../config/database.php';

try {
    $sql = "SELECT 
        (SELECT cpu_usage FROM metrics WHERE cpu_usage > 0 ORDER BY id DESC LIMIT 1) AS cpu_usage,
        (SELECT ram_usage FROM metrics WHERE ram_usage > 0 ORDER BY id DESC LIMIT 1) AS ram_usage,
        (SELECT disk_usage FROM metrics WHERE disk_usage > 0 ORDER BY id DESC LIMIT 1) AS disk_usage,
        (SELECT swap_usage FROM metrics WHERE swap_usage > 0 ORDER BY id DESC LIMIT 1) AS swap_usage,
        (SELECT network_rx_kb FROM metrics WHERE network_rx_kb > 0 ORDER BY id DESC LIMIT 1) AS network_rx_kb,
        (SELECT network_tx_kb FROM metrics WHERE network_tx_kb > 0 ORDER BY id DESC LIMIT 1) AS network_tx_kb";

    $stmt = $pdo->query($sql);
    $data = $stmt->fetch();

    echo json_encode($data ?: [
        "cpu_usage" => 0, 
        "ram_usage" => 0, 
        "disk_usage" => 0, 
        "swap_usage" => 0, 
        "network_rx_kb" => 0, 
        "network_tx_kb" => 0
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>
