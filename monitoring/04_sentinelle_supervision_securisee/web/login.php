<?php
session_start();
require_once __DIR__ . '/config/database.php';

$error = '';
$success = '';

// 1. Garantir que la table users existe
try {
    $pdo->exec("CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
} catch (PDOException $e) {}

// 2. Vérifier si un utilisateur existe déjà
$stmt = $pdo->query("SELECT COUNT(*) FROM users");
$user_count = (int)$stmt->fetchColumn();

// 3. Création du premier compte Admin (si la BDD est vide)
if ($user_count === 0 && isset($_POST['register_action'])) {
    $u = trim($_POST['username'] ?? '');
    $p = trim($_POST['password'] ?? '');
    if (!empty($u) && !empty($p)) {
        $hash = password_hash($p, PASSWORD_BCRYPT);
        $ins = $pdo->prepare("INSERT INTO users (username, password) VALUES (:u, :p)");
        $ins->execute([':u' => $u, ':p' => $hash]);
        $success = "Compte administrateur créé avec succès ! Vous pouvez maintenant vous connecter.";
        $user_count = 1;
    } else {
        $error = "Veuillez remplir tous les champs.";
    }
}

// 4. Traitement de la connexion classique
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_action'])) {
    $user = trim($_POST['username'] ?? '');
    $pass = trim($_POST['password'] ?? '');

    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :u");
    $stmt->execute([':u' => $user]);
    $account = $stmt->fetch();

    if ($account && password_verify($pass, $account['password'])) {
        $_SESSION['admin_logged'] = true;
        $_SESSION['username'] = $account['username'];
        header('Location: index.php');
        exit;
    } else {
        $error = "Identifiants incorrects.";
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Sentinelle V4 - Connexion Admin</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .login-box { max-width: 420px; margin: 60px auto; background: #1e293b; padding: 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.5); }
        .form-group { margin-bottom: 15px; text-align: left; }
        .form-group label { display: block; margin-bottom: 5px; color: #94a3b8; }
        .form-group input { width: 100%; padding: 10px; border-radius: 5px; border: 1px solid #334155; background: #0f172a; color: white; box-sizing: border-box; }
        .btn-submit { width: 100%; padding: 10px; background: #0284c7; color: white; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; }
        .btn-submit:hover { background: #0369a1; }
        .error { color: #ef4444; margin-bottom: 15px; }
        .success { color: #22c55e; margin-bottom: 15px; }
    </style>
</head>
<body>
    <div class="login-box">
        <?php if ($user_count === 0): ?>
            <h2>➕ Initialisation du Compte Admin</h2>
            <p style="color:#94a3b8; font-size:0.9rem;">Aucun compte trouvé en BDD. Définissez les identifiants Administrateur :</p>
            <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
            <form method="POST">
                <input type="hidden" name="register_action" value="1">
                <div class="form-group">
                    <label>Nom d'utilisateur</label>
                    <input type="text" name="username" value="admin" required>
                </div>
                <div class="form-group">
                    <label>Mot de passe</label>
                    <input type="password" name="password" placeholder="Mot de passe admin" required>
                </div>
                <button type="submit" class="btn-submit">Créer le compte Admin</button>
            </form>
        <?php else: ?>
            <h2>🔒 Connexion Admin</h2>
            <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
            <?php if ($success): ?><div class="success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
            <form method="POST">
                <input type="hidden" name="login_action" value="1">
                <div class="form-group">
                    <label>Nom d'utilisateur</label>
                    <input type="text" name="username" required>
                </div>
                <div class="form-group">
                    <label>Mot de passe</label>
                    <input type="password" name="password" required>
                </div>
                <button type="submit" class="btn-submit">Se connecter</button>
            </form>
        <?php endif; ?>
        <p style="margin-top:20px; text-align:center;"><a href="index.php" style="color:#38bdf8; text-decoration:none;">⬅ Retour au Dashboard</a></p>
    </div>
</body>
</html>
