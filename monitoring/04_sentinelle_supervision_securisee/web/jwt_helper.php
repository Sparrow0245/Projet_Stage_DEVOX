<?php
/**
 * Sentinelle V4 - Helper JWT & Google Authenticator (TOTP)
 * Emplacement : monitoring/04_sentinelle_supervision_securisee/web/jwt_helper.php
 */

define('JWT_SECRET_KEY', 'Sentinelle_V4_Super_Secret_JWT_Key_2026!');

/**
 * Encodage Base64Url (pour conformité JWT)
 */
function base64UrlEncode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

/**
 * Décodage Base64Url
 */
function base64UrlDecode($data) {
    return base64_decode(strtr($data, '-_', '+/'));
}

/**
 * Génère un jeton JWT
 */
function generateJWT($userId, $username, $role) {
    $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
    $payload = json_encode([
        'sub'      => $userId,
        'username' => $username,
        'role'     => $role,
        'iat'      => time(),
        'exp'      => time() + (3600 * 8) // Expire dans 8 heures
    ]);

    $base64Header  = base64UrlEncode($header);
    $base64Payload = base64UrlEncode($payload);

    $signature = hash_hmac('sha256', $base64Header . "." . $base64Payload, JWT_SECRET_KEY, true);
    $base64Signature = base64UrlEncode($signature);

    return $base64Header . "." . $base64Payload . "." . $base64Signature;
}

/**
 * Vérifie et décode un jeton JWT
 */
function verifyJWT($jwt) {
    if (empty($jwt)) return false;

    $parts = explode('.', $jwt);
    if (count($parts) !== 3) return false;

    $header    = base64UrlDecode($parts[0]);
    $payload   = base64UrlDecode($parts[1]);
    $signature = $parts[2];

    $payloadData = json_decode($payload, true);
    if (!$payloadData || !isset($payloadData['exp'])) return false;

    // Vérification de la date d'expiration
    if ($payloadData['exp'] < time()) return false;

    // Re-signature pour contrôle d'intégrité
    $expectedSignature = base64UrlEncode(
        hash_hmac('sha256', base64UrlEncode($header) . "." . base64UrlEncode($payload), JWT_SECRET_KEY, true)
    );

    if (hash_equals($expectedSignature, $signature)) {
        return $payloadData;
    }

    return false;
}

/**
 * Vérifie un code Google Authenticator (TOTP RFC 6238)
 */
function verifyGoogleAuthenticator($secret, $code, $discrepancy = 1) {
    if (empty($secret) || empty($code)) return false;

    $base32chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    $secret = strtoupper($secret);
    $binarySecret = '';

    for ($i = 0; $i < strlen($secret); $i++) {
        $pos = strpos($base32chars, $secret[$i]);
        if ($pos === false) continue;
        $binarySecret .= sprintf('%05b', $pos);
    }

    $binarySecret = substr($binarySecret, 0, floor(strlen($binarySecret) / 8) * 8);
    $bytesSecret  = '';
    for ($i = 0; $i < strlen($binarySecret); $i += 8) {
        $bytesSecret .= chr(bindec(substr($binarySecret, $i, 8)));
    }

    $currentTime = floor(time() / 30);

    for ($i = -$discrepancy; $i <= $discrepancy; $i++) {
        $timeBin = pack('N*', 0) . pack('N*', $currentTime + $i);
        $hmac = hash_hmac('sha1', $timeBin, $bytesSecret, true);
        $offset = ord(substr($hmac, -1)) & 0x0F;
        $hashpart = substr($hmac, $offset, 4);
        $value = unpack('N', $hashpart)[1] & 0x7FFFFFFF;
        $calculatedCode = str_pad($value % 1000000, 6, '0', STR_PAD_LEFT);

        if (hash_equals($calculatedCode, trim($code))) {
            return true;
        }
    }

    return false;
}
