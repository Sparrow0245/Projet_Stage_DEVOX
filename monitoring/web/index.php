<!DOCTYPE html>

<html lang="fr">

<head>
  <meta http-equiv="refresh" content="60">

<meta charset="UTF-8">

<title>
Sentinelle Monitoring
</title>


<link rel="stylesheet" href="assets/css/style.css">


<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>


</head>


<body>


<header>

<h1>
🛡️ Sentinelle Monitoring
</h1>


<nav>

<a href="index.php">
Dashboard
</a>

<a href="historique.php">
Historique
</a>


</nav>


</header>



<section class="dashboard">


<div class="card">

<h2>
CPU
</h2>

<canvas id="cpuChart"></canvas>

</div>



<div class="card">

<h2>
RAM
</h2>

<canvas id="ramChart"></canvas>

</div>



<div class="card">

<h2>
Disque
</h2>

<canvas id="diskChart"></canvas>

</div>


</section>



<script src="assets/js/dashboard.js"></script>


</body>

</html>
