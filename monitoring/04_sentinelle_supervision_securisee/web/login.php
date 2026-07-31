<?php
session_start();
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/totp_helper.php';

$error = '';
$success = '';

// 1. Mise à jour schéma BDD pour ajouter totp_secret
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        totp_secret VARCHAR(32) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS totp_secret VARCHAR(32) DEFAULT NULL;");
} catch (PDOException $e) {}

$stmt = $pdo->query("SELECT COUNT(*) FROM users");
$user_count = (int)$stmt->fetchColumn();

// ÉTAPE A : Inscription compte initial s'il n'y a personne
if ($user_count === 0 && isset($_POST['register_action'])) {
    $u = trim($_POST['username'] ?? '');
    $p = trim($_POST['password'] ?? '');
    if (!empty($u) && !empty($p)) {
        $secret = TOTP::generateSecret();
        $hash = password_hash($p, PASSWORD_BCRYPT);
        $ins = $pdo->prepare("INSERT INTO users (username, password, totp_secret) VALUES (:u, :p, :s)");
        $ins->execute([':u' => $u, ':p' => $hash, ':s' => $secret]);
        $success = "Compte créé ! Scannez le QR Code ci-dessous avec Google Authenticator.";
        $user_count = 1;
    } else {
        $error = "Veuillez remplir tous les champs.";
    }
}

// ÉTAPE B : Vérification étape 1 (Mot de passe)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_step1'])) {
    $user = trim($_POST['username'] ?? '');
    $pass = trim($_POST['password'] ?? '');

    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :u");
    $stmt->execute([':u' => $user]);
    $account = $stmt->fetch();

    if ($account && password_verify($pass, $account['password'])) {
        // Si pas encore de clé TOTP, on en génère une
        if (empty($account['totp_secret'])) {
            $secret = TOTP::generateSecret();
            $upd = $pdo->prepare("UPDATE users SET totp_secret = :s WHERE id = :id");
            $upd->execute([':s' => $secret, ':id' => $account['id']]);
            $account['totp_secret'] = $secret;
        }

        $_SESSION['pending_user_id'] = $account['id'];
        $_SESSION['pending_username'] = $account['username'];
        $_SESSION['pending_totp_secret'] = $account['totp_secret'];
        $_SESSION['login_step'] = 2;
    } else {
        $error = "Identifiants incorrects.";
    }
}

// ÉTAPE C : Vérification étape 2 (Code A2F 6 chiffres)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_step2'])) {
    $code = trim($_POST['totp_code'] ?? '');
    $secret = $_SESSION['pending_totp_secret'] ?? '';

    if (TOTP::verifyCode($secret, $code)) {
        $_SESSION['admin_logged'] = true;
        $_SESSION['username'] = $_SESSION['pending_username'];
        unset($_SESSION['pending_user_id'], $_SESSION['pending_username'], $_SESSION['pending_totp_secret'], $_SESSION['login_step']);
        header('Location: admin.php');
        exit;
    } else {
        $error = "Code Google Authenticator invalide ou expiré.";
    }
}

$step = $_SESSION['login_step'] ?? 1;
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Sentinelle V4 - Connexion A2F</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #0b0f19; color: #e2e8f0; margin: 0; padding: 20px; }
        .login-box { max-width: 440px; margin: 50px auto; background: #1e293b; padding: 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.5); text-align: center; }
        .form-group { margin-bottom: 15px; text-align: left; }
        .form-group label { display: block; margin-bottom: 5px; color: #94a3b8; }
        .form-group input { width: 100%; padding: 10px; border-radius: 5px; border: 1px solid #334155; background: #0f172a; color: white; box-sizing: border-box; }
        .btn-submit { width: 100%; padding: 12px; background: #0284c7; color: white; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; }
        .btn-submit:hover { background: #0369a1; }
        .error { color: #ef4444; margin-bottom: 15px; background: #450a0a; padding: 10px; border-radius: 5px; }
        .success { color: #22c55e; margin-bottom: 15px; background: #052e16; padding: 10px; border-radius: 5px; }
        .qr-code { background: white; padding: 10px; display: inline-block; border-radius: 8px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="login-box">
        <?php if ($user_count === 0): ?>
            <h2>➕ Créer le Compte Admin</h2>
            <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
            <form method="POST">
                <input type="hidden" name="register_action" value="1">
                <div class="form-group"><label>Utilisateur</label><input type="text" name="username" value="admin" required></div>
                <div class="form-group"><label>Mot de passe</label><input type="password" name="password" required></div>
                <button type="submit" class="btn-submit">Créer le compte</button>
            </form>

        <?php elseif ($step === 1): ?>
            <h2>🔒 Connexion Admin (Étape 1/2)</h2>
            <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
            <?php if ($success): ?><div class="success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
            <form method="POST">
                <input type="hidden" name="login_step1" value="1">
                <div class="form-group"><label>Nom d'utilisateur</label><input type="text" name="username" required></div>
                <div class="form-group"><label>Mot de passe</label><input type="password" name="password" required></div>
                <button type="submit" class="btn-submit">Continuer ➡</button>
            </form>

        <?php elseif ($step === 2): ?>
            <h2>🔑 Valider l'A2F (Étape 2/2)</h2>
            <p style="color:#94a3b8; font-size:0.9rem;">Scannez ce QR Code dans <strong>Google Authenticator</strong> si ce n'est pas déjà fait :</p>
            <div class="qr-code">
                <img src="<?= TOTP::getQRCodeUrl($_SESSION['pending_username'], $_SESSION['pending_totp_secret']) ?>" alt="QR Code A2F">
            </div>
            <p style="font-size:0.8rem; color:#f59e0b;">Clé secrète : <code><?= htmlspecialchars($_SESSION['pending_totp_secret']) ?></code></p>
            
            <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
            <form method="POST">
                <input type="hidden" name="login_step2" value="1">
                <div class="form-group">
                    <label>Code à 6 chiffres (Google Authenticator)</label>
                    <input type="text" name="totp_code" maxlength="6" placeholder="ex: 123456" autocomplete="off" autofocus required style="text-align:center; font-size:1.4rem; letter-spacing:4px;">
                </div>
                <button type="submit" class="btn-submit">Se connecter au Dashboard Admin</button>
            </form>
        <?php endif; ?>
        <p style="margin-top:20px;"><a href="index.php" style="color:#38bdf8; text-decoration:none;">⬅ Retour au site</a></p>
    </div>
</body>
</html>
