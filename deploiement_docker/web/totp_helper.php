<?php

/**
 * Sentinelle V4
 * Helper TOTP compatible Google Authenticator.
 *
 * Cette copie appartient à la couche de déploiement Docker.
 */

class TOTP
{
    private static $base32chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    public static function generateSecret($length = 16)
    {
        $secret = '';

        for ($i = 0; $i < $length; $i++) {
            $secret .= self::$base32chars[random_int(0, 31)];
        }

        return $secret;
    }

    public static function verifyCode($secret, $code, $discrepancy = 1)
    {
        $currentTimeSlice = floor(time() / 30);

        for ($i = -$discrepancy; $i <= $discrepancy; $i++) {

            $calculatedCode = self::calculateCode(
                $secret,
                $currentTimeSlice + $i
            );

            if ($calculatedCode === str_pad($code, 6, '0', STR_PAD_LEFT)) {
                return true;
            }
        }

        return false;
    }

    private static function calculateCode($secret, $timeSlice)
    {
        $secretKey = self::base32Decode($secret);

        $time = pack('N*', 0) . pack('N*', $timeSlice);

        $hmac = hash_hmac(
            'sha1',
            $time,
            $secretKey,
            true
        );

        $offset = ord(substr($hmac, -1)) & 0x0F;

        $hashpart = substr($hmac, $offset, 4);

        $value = unpack('N', $hashpart)[1] & 0x7FFFFFFF;

        return str_pad(
            $value % 1000000,
            6,
            '0',
            STR_PAD_LEFT
        );
    }

    private static function base32Decode($secret)
    {
        if (empty($secret)) {
            return '';
        }

        $secret = strtoupper($secret);

        $buffer = 0;
        $bitsLeft = 0;
        $result = '';

        for ($i = 0; $i < strlen($secret); $i++) {

            $val = strpos(
                self::$base32chars,
                $secret[$i]
            );

            if ($val === false) {
                continue;
            }

            $buffer = ($buffer << 5) | $val;
            $bitsLeft += 5;

            if ($bitsLeft >= 8) {

                $bitsLeft -= 8;

                $result .= chr(
                    ($buffer >> $bitsLeft) & 0xFF
                );
            }
        }

        return $result;
    }

    public static function getQRCodeUrl(
        $name,
        $secret,
        $title = 'Sentinelle-V4'
    ) {
        $urlencoded = urlencode(
            "otpauth://totp/{$title}:{$name}" .
            "?secret={$secret}" .
            "&issuer={$title}"
        );

        return "https://api.qrserver.com/v1/create-qr-code/" .
            "?data={$urlencoded}&size=200x200";
    }
}
