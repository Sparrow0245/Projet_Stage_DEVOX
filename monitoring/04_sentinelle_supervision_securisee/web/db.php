<?php
/**
 * Sentinelle V4 - Connexion à la Base de Données
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/db.php
 */

$host = '127.0.0.1';
$db   = 'sentinelle';
$user = 'sentinelle';
$pass = 'SentinelleSecurePass2026!';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erreur de connexion à la base de données.']);
    exit;
}
