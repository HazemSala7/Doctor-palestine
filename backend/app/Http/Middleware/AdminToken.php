<?php

namespace App\Http\Middleware;

use App\Http\Controllers\Admin\AdminAuthController;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Stateless bearer token signed with APP_KEY: no package or migration needed.
 * Changing APP_KEY signs every admin out.
 */
class AdminToken
{
    private const TTL = 60 * 60 * 24 * 7; // one week

    public static function issue(int $userId): string
    {
        $payload = self::b64(json_encode(['uid' => $userId, 'exp' => time() + self::TTL]));

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

        $user = DB::table('users')->where('id', $claims['uid'] ?? 0)->first();
        if (! $user || ! AdminAuthController::isAdmin($user)) {
            return $this->deny();
        }

        $request->attributes->set('admin', $user);

        return $next($request);
    }

    private function deny()
    {
        return response()->json(['message' => 'انتهت الجلسة، سجّل الدخول من جديد'], 401);
    }

    private static function sign(string $payload): string
    {
        return self::b64(hash_hmac('sha256', $payload, (string) config('app.key'), true));
    }

    private static function b64(string $raw): string
    {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
    }
}
