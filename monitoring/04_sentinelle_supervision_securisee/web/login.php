<?php
/**
 * Sentinelle V4 - Connexion JWT & Google Authenticator
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/login.php
 */

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/jwt_helper.php';

$error = '';

// Si déjà connecté via JWT
if (isset($_COOKIE['sentinelle_jwt'])) {
    $userData = verifyJWT($_COOKIE['sentinelle_jwt']);
    if ($userData) {
        header('Location: admin.php');
        exit;
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    $totpCode = trim($_POST['totp_code'] ?? '');

    if (!empty($username) && !empty($password) && !empty($totpCode)) {
        $stmt = $pdo->prepare("SELECT id, username, password, role, totp_secret FROM users WHERE username = :username LIMIT 1");
        $stmt->execute(['username' => $username]);
        $user = $stmt->fetch();

        if ($user && password_verify($password, $user['password'])) {
            // Vérification 2FA Google Authenticator
            if (!empty($user['totp_secret']) && verifyGoogleAuthenticator($user['totp_secret'], $totpCode)) {
                
                // Génération du Token JWT
                $jwtToken = generateJWT($user['id'], $user['username'], $user['role']);

                // Définition du Cookie HTTPOnly contenant le JWT
                setcookie('sentinelle_jwt', $jwtToken, [
                    'expires'  => time() + (3600 * 8),
                    'path'     => '/',
                    'httponly' => true,
                    'samesite' => 'Strict'
                ]);

                header('Location: admin.php');
                exit;
            } else {
                $error = "Code Google Authenticator valide requis.";
            }
        } else {
            $error = "Identifiants incorrects.";
        }
    } else {
        $error = "Veuillez remplir l'ensemble des champs (y compris le code 2FA).";
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinelle V4 - Connexion JWT & 2FA</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body class="login-page">
    <div class="login-card">
        <h2>Sentinelle V4</h2>
        <p>Authentification JWT & Google Authenticator</p>

        <?php if ($error): ?>
            <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <form method="POST" action="login.php">
            <div class="form-group">
                <label for="username">Nom d'utilisateur</label>
                <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            <div class="form-group">
                <label for="password">Mot de passe</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            <div class="form-group">
                <label for="totp_code">Code Google Authenticator (6 chiffres)</label>
                <input type="text" id="totp_code" name="totp_code" maxlength="6" pattern="[0-9]{6}" required placeholder="123456" autocomplete="off">
            </div>
            <button type="submit" class="btn">Valider & Obtenir le Token</button>
        </form>
        <p class="back-link"><a href="index.php">&larr; Retour au dashboard public</a></p>
    </div>
</body>
</html>
