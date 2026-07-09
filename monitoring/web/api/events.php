<?php

require_once "../config/database.php";


$sql = "
SELECT
type,
ip,
message,
severity,
action,
created_at

FROM events

ORDER BY id DESC

LIMIT 20
";


$stmt = $pdo->prepare($sql);
$stmt->execute();


$data = $stmt->fetchAll(PDO::FETCH_ASSOC);


header(
    "Content-Type: application/json"
);


echo json_encode($data);

?>
