<?php

$host = 'mariadb';
$db   = 'web';
$user = 'webuser';
$pass = 'WebJelszo123!';

try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass
    );

    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "<h1>PHP → MariaDB kapcsolat OK!</h1>";

    $version = $pdo->query("SELECT VERSION()")->fetchColumn();

    echo "<p>MariaDB verzió: " . htmlspecialchars($version) . "</p>";

} catch (PDOException $e) {
    echo "<h1>Adatbázis hiba</h1>";
    echo "<pre>" . htmlspecialchars($e->getMessage()) . "</pre>";
}