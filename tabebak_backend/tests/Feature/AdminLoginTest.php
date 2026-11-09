<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** The dashboard is entered with a phone number and password only. */
class AdminLoginTest extends TestCase
{
    public function createApplication()
    {
        // Never let a test reach the database configured in .env.
        foreach (['DB_CONNECTION' => 'sqlite', 'DB_DATABASE' => ':memory:', 'APP_URL' => 'http://localhost'] as $k => $v) {
            putenv("$k=$v");
            $_ENV[$k] = $_SERVER[$k] = $v;
        }

        return parent::createApplication();
    }

    protected function setUp(): void
    {
        parent::setUp();
        $this->assertSame(':memory:', config('database.connections.' . config('database.default') . '.database'));

        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email')->unique();
            $t->string('password');
            $t->unsignedBigInteger('role_id')->nullable();
        });
        Schema::create('roles', function (Blueprint $t) {
            $t->id();
            $t->string('name');
        });
        (require database_path('migrations/2026_11_09_000002_add_phone_to_users.php'))->up();

        DB::table('roles')->insert([['id' => 1, 'name' => 'admin'], ['id' => 2, 'name' => 'user']]);
        DB::table('users')->insert([
            ['id' => 1, 'name' => 'المدير', 'email' => 'old@a.ps', 'password' => Hash::make('secret1'), 'role_id' => 1, 'phone' => null],
            ['id' => 2, 'name' => 'مدير النظام', 'email' => 'p@a.ps', 'password' => Hash::make('123456'), 'role_id' => 1, 'phone' => '123456789'],
            ['id' => 3, 'name' => 'موظف', 'email' => 'u@a.ps', 'password' => Hash::make('123456'), 'role_id' => 2, 'phone' => '0599000000'],
        ]);
    }

    private function login(array $body)
    {
        return $this->postJson('/api/admin/login', $body, ['Accept' => 'application/json']);
    }

    public function test_an_admin_signs_in_with_a_phone_number()
    {
        $res = $this->login(['phone' => '123456789', 'password' => '123456'])->assertOk()
            ->assertJsonPath('user.phone', '123456789')
            ->assertJsonPath('user.name', 'مدير النظام');

        $this->getJson('/api/admin/me', ['Authorization' => 'Bearer ' . $res->json('token')])
            ->assertOk()->assertJsonPath('phone', '123456789');
    }

    public function test_spaces_and_dashes_in_the_number_do_not_matter()
    {
        $this->login(['phone' => ' 123-456 789 ', 'password' => '123456'])->assertOk();
    }

    public function test_a_wrong_password_or_unknown_number_is_refused()
    {
        $message = 'رقم الهاتف أو كلمة المرور غير صحيحة';
        $this->login(['phone' => '123456789', 'password' => 'wrong'])->assertStatus(401)->assertJsonPath('message', $message);
        $this->login(['phone' => '111', 'password' => '123456'])->assertStatus(401)->assertJsonPath('message', $message);
    }

    public function test_an_email_no_longer_signs_in()
    {
        $this->login(['email' => 'p@a.ps', 'password' => '123456'])->assertStatus(422)
            ->assertJsonPath('errors.phone.0', 'رقم الهاتف مطلوب');
        $this->login(['phone' => 'p@a.ps', 'password' => '123456'])->assertStatus(401);
    }

    public function test_a_number_with_no_digits_cannot_match_an_account_without_a_phone()
    {
        $this->login(['phone' => 'old', 'password' => 'secret1'])->assertStatus(401);
    }

    public function test_only_admins_may_enter()
    {
        $this->login(['phone' => '0599000000', 'password' => '123456'])->assertStatus(403);
    }
}
