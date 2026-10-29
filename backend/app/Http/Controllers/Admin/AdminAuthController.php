<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Middleware\AdminToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

/**
 * Signs in with the existing `users` table (the same accounts Voyager uses).
 * When users have a Voyager role, only the `admin` role may sign in.
 */
class AdminAuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = DB::table('users')->where('email', $request->input('email'))->first();
        if (! $user || ! Hash::check($request->input('password'), $user->password)) {
            return response()->json(['message' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة'], 401);
        }
        if (! $this->isAdmin($user)) {
            return response()->json(['message' => 'هذا الحساب لا يملك صلاحية الدخول للوحة التحكم'], 403);
        }

        return response()->json([
            'token' => AdminToken::issue($user->id),
            'user' => ['name' => $user->name, 'email' => $user->email],
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->attributes->get('admin');

        return response()->json(['name' => $user->name, 'email' => $user->email]);
    }

    public static function isAdmin($user): bool
    {
        if (! Schema::hasColumn('users', 'role_id') || ! Schema::hasTable('roles')) {
            return true;
        }

        return DB::table('roles')->where('id', $user->role_id)->value('name') === 'admin';
    }
}
