<?php

require_once "../config/database.php";


$sql = "
SELECT
cpu_usage,
ram_usage,
disk_usage,
load_average,
created_at

FROM metrics

ORDER BY id DESC

LIMIT 20
";


$stmt = $pdo->prepare($sql);
$stmt->execute();


$data = $stmt->fetchAll(PDO::FETCH_ASSOC);


header(
    "Content-Type: application/json"
);


echo json_encode(
    array_reverse($data)
);

?>
