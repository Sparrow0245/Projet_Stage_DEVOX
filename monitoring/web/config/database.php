<?php

$host = "localhost";
$dbname = "sentinelle";
$user = "sentinelle";
$password = "serveur";


try {

    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $user,
        $password
    );


    $pdo->setAttribute(
        PDO::ATTR_ERRMODE,
        PDO::ERRMODE_EXCEPTION
    );


}
catch(PDOException $e){

    die(
        "Erreur connexion BDD : "
        . $e->getMessage()
    );

}

?>
