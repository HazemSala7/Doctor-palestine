<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Middleware\AdminToken;
use App\Services\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

/**
 * Signs in by phone number, from the `users` table (the same accounts Voyager uses).
 * When users have a Voyager role, only the `admin` role may sign in.
 */
class AdminAuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'phone.required' => 'رقم الهاتف مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
        ]);

        // An empty result must not match the accounts that have no number.
        $phone = Booking::normalizePhone($request->input('phone'));
        $user = $phone === '' ? null : DB::table('users')->where('phone', $phone)->first();
        if (! $user || ! Hash::check($request->input('password'), $user->password)) {
            return response()->json(['message' => 'رقم الهاتف أو كلمة المرور غير صحيحة'], 401);
        }
        if (! $this->isAdmin($user)) {
            return response()->json(['message' => 'هذا الحساب لا يملك صلاحية الدخول للوحة التحكم'], 403);
        }

        return response()->json([
            'token' => AdminToken::issue($user->id),
            'user' => ['name' => $user->name, 'phone' => $user->phone],
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->attributes->get('admin');

        return response()->json(['name' => $user->name, 'phone' => $user->phone]);
    }

    public static function isAdmin($user): bool
    {
        if (! Schema::hasColumn('users', 'role_id') || ! Schema::hasTable('roles')) {
            return true;
        }

        return DB::table('roles')->where('id', $user->role_id)->value('name') === 'admin';
    }
}
