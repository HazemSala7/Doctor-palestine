<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Bearer token for doctors in the mobile app, built like AdminToken but
 * signed with a different key so a doctor token can never pass as an admin
 * one. Changing the password, deactivating the account or moving it to
 * another doctor signs the doctor out.
 */
class DoctorToken
{
    private const TTL = 60 * 60 * 24 * 30; // thirty days

    public static function issue($account): string
    {
        $payload = self::b64(json_encode([
            'aid' => (int) $account->id,
            'pw' => self::passwordStamp($account),
            'exp' => time() + self::TTL,
        ]));

        return $payload . '.' . self::sign($payload);
    }

    public function handle(Request $request, Closure $next)
    {
        $parts = explode('.', (string) $request->bearerToken());
        if (count($parts) !== 2 || ! hash_equals(self::sign($parts[0]), $parts[1])) {
            return $this->deny();
        }

        $claims = json_decode(base64_decode(strtr($parts[0], '-_', '+/')), true);
        if (! is_array($claims) || ($claims['exp'] ?? 0) < time()) {
            return $this->deny();
        }

        $account = DB::table('doctor_accounts')->where('id', $claims['aid'] ?? 0)->first();
        if (! $account || ! $account->active || ! hash_equals(self::passwordStamp($account), (string) ($claims['pw'] ?? ''))) {
            return $this->deny();
        }

        $request->attributes->set('doctor_account', $account);

        return $next($request);
    }

    /** Changes whenever the password or the account's doctor does. */
    private static function passwordStamp($account): string
    {
        return substr(hash('sha256', $account->password . '|' . $account->doctor_id), 0, 16);
    }

    private function deny()
    {
        return response()->json(['message' => 'انتهت الجلسة، سجّل الدخول من جديد'], 401);
    }

    private static function sign(string $payload): string
    {
        return self::b64(hash_hmac('sha256', $payload, 'doctor|' . config('app.key'), true));
    }

    private static function b64(string $raw): string
    {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
    }
}
