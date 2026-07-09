<?php

require_once "config/database.php";


$stmt = $pdo->query(
"
SELECT *

FROM events

ORDER BY id DESC

LIMIT 100
"
);


$events = $stmt->fetchAll();


?>


<!DOCTYPE html>

<html lang="fr">


<head>

<meta charset="UTF-8">

<title>
Historique Sentinelle
</title>


<link rel="stylesheet" href="assets/css/style.css">


</head>


<body>


<header>

<h1>
Historique des événements
</h1>


<a href="index.php">
Retour dashboard
</a>


</header>



<table>


<tr>

<th>Date</th>

<th>Type</th>

<th>IP</th>

<th>Niveau</th>

<th>Action</th>

</tr>



<?php foreach($events as $event): ?>


<tr>

<td>
<?= htmlspecialchars($event["created_at"]) ?>
</td>


<td>
<?= htmlspecialchars($event["type"]) ?>
</td>


<td>
<?= htmlspecialchars($event["ip"]) ?>
</td>


<td>
<?= htmlspecialchars($event["severity"]) ?>
</td>


<td>
<?= htmlspecialchars($event["action"]) ?>
</td>


</tr>


<?php endforeach; ?>


</table>



</body>

</html>
