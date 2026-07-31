<?php
/**
 * Sentinelle V4 - Déconnexion (Suppression du Cookie JWT)
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/logout.php
 */

setcookie('sentinelle_jwt', '', [
    'expires'  => time() - 3600,
    'path'     => '/',
    'httponly' => true,
    'samesite' => 'Strict'
]);

header('Location: login.php');
exit;
