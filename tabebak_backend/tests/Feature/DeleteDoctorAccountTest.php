<?php

namespace Tests\Feature;

use App\Http\Middleware\DoctorToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/** A doctor deletes their own account from the app (App Store guideline 5.1.1(v)). */
class DeleteDoctorAccountTest extends TestCase
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
        $this->withoutMiddleware(ThrottleRequests::class);
        Storage::fake('public');

        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->unsignedBigInteger('category_id')->nullable();
            $t->unsignedBigInteger('city_id')->nullable();
        });
        $migrations = [
            ...glob(database_path('migrations/2026_11_06_*.php')),
            database_path('migrations/2026_11_07_000001_create_reels_table.php'),
            database_path('migrations/2026_11_07_000007_create_staff_members_table.php'),
        ];
        foreach ($migrations as $file) {
            (require $file)->up();
        }

        DB::table('doctors')->insert([['id' => 6, 'name' => 'د. علاء'], ['id' => 7, 'name' => 'د. سامي']]);
        DB::table('doctor_accounts')->insert([
            ['id' => 1, 'doctor_id' => 6, 'phone' => '0591234567', 'password' => Hash::make('secret1')],
            ['id' => 2, 'doctor_id' => 7, 'phone' => '0597654321', 'password' => Hash::make('secret2')],
        ]);
        Storage::disk('public')->put('reels/a.mp4', 'video');
        DB::table('reels')->insert([
            ['id' => 1, 'title' => 'لي', 'doctor_id' => 6, 'video' => 'reels/a.mp4'],
            ['id' => 2, 'title' => 'لغيري', 'doctor_id' => 7, 'video' => null],
        ]);
        DB::table('staff_members')->insert([
            ['type' => 'doctor', 'target_id' => 6, 'name' => 'ممرضة', 'role' => 'تمريض'],
            ['type' => 'doctor', 'target_id' => 7, 'name' => 'سكرتير', 'role' => 'استقبال'],
            ['type' => 'hospital', 'target_id' => 6, 'name' => 'مستشفى بنفس الرقم', 'role' => 'إدارة'],
        ]);
    }

    private function auth(int $accountId): array
    {
        return ['Authorization' => 'Bearer ' . DoctorToken::issue(DB::table('doctor_accounts')->find($accountId)), 'Accept' => 'application/json'];
    }

    public function test_wrong_password_deletes_nothing()
    {
        $this->postJson('/api/doctor/account/delete', ['password' => 'nope'], $this->auth(1))
            ->assertStatus(422)->assertJsonValidationErrors('password');
        $this->postJson('/api/doctor/account/delete', [], $this->auth(1))
            ->assertStatus(422)->assertJsonValidationErrors('password');

        $this->assertSame(2, DB::table('doctor_accounts')->count());
        $this->assertSame(2, DB::table('reels')->count());
    }

    public function test_deleting_removes_the_login_reels_and_team_only_for_that_doctor()
    {
        $headers = $this->auth(1);
        $this->postJson('/api/doctor/account/delete', ['password' => 'secret1'], $headers)->assertOk();

        $this->assertNull(DB::table('doctor_accounts')->find(1));
        $this->assertSame([2], DB::table('reels')->pluck('id')->all());
        Storage::disk('public')->assertMissing('reels/a.mp4');
        $this->assertSame(['سكرتير', 'مستشفى بنفس الرقم'], DB::table('staff_members')->orderBy('id')->pluck('name')->all());

        // The listing stays, the other doctor is untouched, and the old token is dead.
        $this->assertSame(2, DB::table('doctors')->count());
        $this->assertNotNull(DB::table('doctor_accounts')->find(2));
        $this->getJson('/api/doctor/me', $headers)->assertStatus(401);
    }
}
