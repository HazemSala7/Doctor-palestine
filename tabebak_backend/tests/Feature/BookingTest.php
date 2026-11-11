<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * Booking flow end to end on an in-memory SQLite database:
 * admin creates a doctor account -> patient books -> doctor manages.
 */
class BookingTest extends TestCase
{
    public function createApplication()
    {
        // Never let a test reach the database configured in .env. APP_URL's
        // sub-folder would otherwise prefix every test request.
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
        // These tests book far more often than the per-minute limit allows.
        $this->withoutMiddleware(ThrottleRequests::class);

        // Saturday 08:00 in Palestine.
        Carbon::setTestNow(Carbon::create(2026, 11, 7, 8, 0, 0, 'Asia/Hebron'));

        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email');
            $t->string('password');
        });
        Schema::create('doctor_categories', function (Blueprint $t) {
            $t->id();
            $t->string('name');
        });
        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->unsignedBigInteger('category_id')->nullable();
            $t->string('mobile')->nullable();
            $t->string('address')->nullable();
        });
        foreach (glob(database_path('migrations/2026_11_06_*.php')) as $file) {
            (require $file)->up();
        }

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('doctor_categories')->insert(['id' => 1, 'name' => 'الأسنان']);
        DB::table('doctors')->insert(['id' => 6, 'name' => 'د. علاء', 'category_id' => 1, 'image' => 'doctors/a.jpg']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function admin(): array
    {
        return ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json'];
    }

    private function createAccount(): array
    {
        return $this->postJson('/api/admin/doctor-accounts', [
            'doctor_id' => 6, 'phone' => '059-123 4567', 'password' => 'secret1', 'active' => 1, 'booking_enabled' => 1,
        ], $this->admin())->assertCreated()->json();
    }

    private function doctorLogin(string $password = 'secret1'): string
    {
        return $this->postJson('/api/doctor/login', ['phone' => '0591234567', 'password' => $password])
            ->assertOk()->json('token');
    }

    private function book(array $over = [])
    {
        return $this->postJson('/api/doctors/6/appointments', $over + [
            'patient_name' => 'محمد', 'patient_phone' => '0599 000 111', 'date' => '2026-11-08', 'time' => '10:00',
        ]);
    }

    public function test_a_doctor_signs_in_with_any_form_of_the_number()
    {
        $res = $this->postJson('/api/admin/doctor-accounts', [
            'doctor_id' => 6, 'phone' => '+972 59-123-4567', 'password' => 'secret1', 'active' => 1, 'booking_enabled' => 1,
        ], $this->admin())->assertCreated();
        $this->assertSame('0591234567', $res->json('phone'));

        foreach (['0591234567', '059-123 4567', '+972591234567', '+970 59 123 4567', '00970591234567', '9720591234567'] as $form) {
            $this->postJson('/api/doctor/login', ['phone' => $form, 'password' => 'secret1'])->assertOk();
        }
        $this->postJson('/api/doctor/login', ['phone' => '+962591234567', 'password' => 'secret1'])->assertStatus(401);
    }

    public function test_accounts_already_saved_with_a_country_code_keep_working()
    {
        foreach ([[1, '972591234567'], [2, '970592222222'], [3, '0593333333'], [4, '970593333333']] as [$id, $phone]) {
            DB::table('doctor_accounts')->insert(['id' => $id, 'doctor_id' => 100 + $id, 'phone' => $phone, 'password' => Hash::make('secret1'), 'active' => 1]);
        }

        (require database_path('migrations/2026_11_09_000003_local_format_doctor_account_phones.php'))->up();

        $this->assertSame(
            ['0591234567', '0592222222', '0593333333', '970593333333'],
            DB::table('doctor_accounts')->orderBy('id')->pluck('phone')->all()
        );
        $this->postJson('/api/doctor/login', ['phone' => '+972 59 123 4567', 'password' => 'secret1'])->assertOk();
    }

    public function test_admin_manages_accounts_without_leaking_passwords()
    {
        $this->getJson('/api/doctors/6/booking')->assertOk()->assertJson(['enabled' => false]);

        $row = $this->createAccount();
        $this->assertSame('0591234567', $row['phone']);
        $this->assertArrayNotHasKey('password', $row);
        $this->assertTrue(Hash::check('secret1', DB::table('doctor_accounts')->value('password')));

        // Phone and doctor are unique.
        $this->postJson('/api/admin/doctor-accounts', ['doctor_id' => 6, 'phone' => '0591234567', 'password' => 'secret1'], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['doctor_id', 'phone']);
        // Password is required on create, optional on edit (and then kept).
        $this->postJson('/api/admin/doctor-accounts', ['doctor_id' => 7, 'phone' => '0590000000'], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['password']);
        $this->postJson("/api/admin/doctor-accounts/{$row['id']}", ['_method' => 'PUT', 'doctor_id' => 6, 'phone' => '0591234567', 'password' => '', 'active' => 1], $this->admin())
            ->assertOk()->assertJsonMissing(['password']);
        $this->doctorLogin();

        $list = $this->getJson('/api/admin/doctor-accounts', $this->admin())->assertOk()->json('data');
        $this->assertArrayNotHasKey('password', $list[0]);
        // Work schedule columns keep their defaults: the dashboard never sends them.
        $this->assertSame('0,1,2,3,4,5', $list[0]['work_days']);
    }

    public function test_patient_books_and_cancels()
    {
        $this->createAccount();

        $avail = $this->getJson('/api/doctors/6/booking?date=2026-11-08')->assertOk()->json();
        $this->assertTrue($avail['enabled']);
        $this->assertSame('09:00', $avail['slots'][0]['time']);
        $this->assertCount(16, $avail['slots']); // 09:00 .. 16:30 every 30 min

        // Today: slots before 08:00 now are gone, the rest are open.
        $today = $this->getJson('/api/doctors/6/booking')->json('slots');
        $this->assertTrue($today[0]['available']);

        $booked = $this->book()->assertCreated()->json();
        $this->assertSame('pending', $booked['status']);
        $this->assertSame('0599000111', $booked['patient_phone']);
        $this->assertNotEmpty($booked['code']);

        // The slot is now taken, for the API and for a second patient.
        $slots = collect($this->getJson('/api/doctors/6/booking?date=2026-11-08')->json('slots'))->keyBy('time');
        $this->assertFalse($slots['10:00']['available']);
        $this->book(['patient_name' => 'سارة'])->assertStatus(409)->assertJsonValidationErrors(['time']);

        // Bad requests.
        $this->book(['date' => '2026-11-13'])->assertStatus(422); // Friday: day off
        $this->book(['date' => '2026-11-06'])->assertStatus(422)->assertJsonValidationErrors(['date']); // past
        $this->book(['date' => '2026-12-31'])->assertStatus(422)->assertJsonValidationErrors(['date']); // too far
        $this->book(['time' => '10:10'])->assertStatus(422)->assertJsonValidationErrors(['time']); // not a slot
        $this->book(['patient_phone' => '12'])->assertStatus(422)->assertJsonValidationErrors(['patient_phone']);
        $this->postJson('/api/doctors/99/appointments', ['patient_name' => 'x y', 'patient_phone' => '0599000111', 'date' => '2026-11-08', 'time' => '10:00'])
            ->assertNotFound();

        // The patient follows and cancels with the code; the slot opens again.
        $this->getJson("/api/appointments/{$booked['code']}")->assertOk()->assertJsonPath('doctor.name', 'د. علاء');
        $this->postJson("/api/appointments/{$booked['code']}/cancel")->assertOk()->assertJsonPath('status', 'cancelled');
        $this->postJson("/api/appointments/{$booked['code']}/cancel")->assertStatus(422);
        $this->book(['patient_name' => 'سارة'])->assertCreated();
        $this->getJson('/api/appointments/nope')->assertNotFound();

        // The admin list never shows the patient's secret code.
        $rows = $this->getJson('/api/admin/appointments', $this->admin())->assertOk()->json('data');
        $this->assertCount(2, $rows);
        $this->assertArrayNotHasKey('code', $rows[0]);
    }

    public function test_doctor_sees_and_manages_own_appointments()
    {
        $this->createAccount();
        $this->postJson('/api/doctor/login', ['phone' => '0591234567', 'password' => 'wrong'])->assertStatus(401);
        $token = $this->doctorLogin();
        $auth = ['Authorization' => "Bearer $token", 'Accept' => 'application/json'];

        $me = $this->getJson('/api/doctor/me', $auth)->assertOk()->json();
        $this->assertSame('د. علاء', $me['doctor']['name']);
        $this->assertSame('الأسنان', $me['doctor']['specialty']);
        $this->assertSame([0, 1, 2, 3, 4, 5], $me['account']['work_days']);

        $id = $this->book()->json('id');
        $this->book(['time' => '09:00', 'date' => '2026-11-07'])->assertCreated();
        // Another doctor's booking must not show up.
        DB::table('doctor_appointments')->insert([
            'doctor_id' => 7, 'code' => 'other', 'patient_name' => 'x', 'patient_phone' => '1', 'date' => '2026-11-08', 'time' => '09:00', 'status' => 'pending',
        ]);

        $res = $this->getJson('/api/doctor/appointments', $auth)->assertOk()->json();
        $this->assertCount(2, $res['data']);
        $this->assertSame('2026-11-07', $res['data'][0]['date']); // soonest first
        $this->assertSame(['today' => 1, 'pending' => 2, 'confirmed' => 0], $res['summary']);
        $this->assertCount(1, $this->getJson('/api/doctor/appointments?scope=today', $auth)->json('data'));

        $this->postJson("/api/doctor/appointments/$id/status", ['status' => 'confirmed'], $auth)->assertOk()->assertJsonPath('status', 'confirmed');
        $this->postJson("/api/doctor/appointments/$id/status", ['status' => 'bogus'], $auth)->assertStatus(422);
        $otherId = DB::table('doctor_appointments')->where('code', 'other')->value('id');
        $this->postJson("/api/doctor/appointments/$otherId/status", ['status' => 'cancelled'], $auth)->assertNotFound();

        // Re-opening a cancelled booking whose slot was taken again is refused.
        $this->postJson("/api/doctor/appointments/$id/status", ['status' => 'cancelled'], $auth)->assertOk();
        $this->book(['patient_name' => 'سارة'])->assertCreated();
        $this->postJson("/api/doctor/appointments/$id/status", ['status' => 'confirmed'], $auth)->assertStatus(409);

        // Schedule.
        $this->putJson('/api/doctor/schedule', [
            'booking_enabled' => true, 'work_days' => [1, 0, 1], 'work_start' => '16:00', 'work_end' => '18:00', 'slot_minutes' => 60,
        ], $auth)->assertOk()->assertJsonPath('account.work_days', [0, 1]);
        $slots = $this->getJson('/api/doctors/6/booking?date=2026-11-08')->json('slots');
        $this->assertSame(['16:00', '17:00'], array_column($slots, 'time'));
        $this->putJson('/api/doctor/schedule', [
            'booking_enabled' => true, 'work_days' => [], 'work_start' => '18:00', 'work_end' => '16:00', 'slot_minutes' => 7,
        ], $auth)->assertStatus(422)->assertJsonValidationErrors(['work_days', 'work_end', 'slot_minutes']);
        $this->putJson('/api/doctor/schedule', [
            'booking_enabled' => false, 'work_days' => [0], 'work_start' => '09:00', 'work_end' => '12:00', 'slot_minutes' => 30,
        ], $auth)->assertOk();
        $this->getJson('/api/doctors/6/booking')->assertJson(['enabled' => false]);
        $this->book(['time' => '09:00'])->assertNotFound();

        // Changing the password signs out the old token.
        $this->postJson('/api/doctor/password', ['current_password' => 'nope', 'password' => 'newpass1'], $auth)->assertStatus(422);
        $fresh = $this->postJson('/api/doctor/password', ['current_password' => 'secret1', 'password' => 'newpass1'], $auth)->assertOk()->json('token');
        $this->getJson('/api/doctor/me', $auth)->assertStatus(401);
        $this->getJson('/api/doctor/me', ['Authorization' => "Bearer $fresh"])->assertOk();
        $this->doctorLogin('newpass1');

        // Deactivated accounts are signed out and can't log in.
        DB::table('doctor_accounts')->update(['active' => 0]);
        $this->getJson('/api/doctor/me', ['Authorization' => "Bearer $fresh"])->assertStatus(401);
        $this->postJson('/api/doctor/login', ['phone' => '0591234567', 'password' => 'newpass1'])->assertStatus(403);
    }

    public function test_moving_an_account_to_another_doctor_signs_it_out()
    {
        DB::table('doctors')->insert([['id' => 7, 'name' => 'د. سارة', 'category_id' => 1], ['id' => 8, 'name' => 'د. ليث', 'category_id' => 1]]);
        $id = $this->createAccount()['id'];
        $auth = ['Authorization' => 'Bearer ' . $this->doctorLogin()];
        $this->getJson('/api/doctor/me', $auth)->assertOk();

        // Editing other fields keeps the session and the password.
        $move = fn (int $doctor, array $over = []) => $this->postJson("/api/admin/doctor-accounts/$id", $over + [
            '_method' => 'PUT', 'doctor_id' => $doctor, 'phone' => '0591234567', 'password' => '', 'active' => 1, 'booking_enabled' => 1,
        ], $this->admin());
        $move(6, ['booking_enabled' => 0])->assertOk();
        $this->getJson('/api/doctor/me', $auth)->assertOk();

        $move(7)->assertOk()->assertJsonPath('doctor_id', 7);
        $this->getJson('/api/doctor/me', $auth)->assertStatus(401);
        $this->getJson('/api/doctors/6/booking')->assertOk()->assertJson(['enabled' => false]);
        $this->getJson('/api/doctors/7/booking')->assertOk()->assertJson(['enabled' => true]);

        // The same login and password now open the new doctor's account.
        $this->getJson('/api/doctor/me', ['Authorization' => 'Bearer ' . $this->doctorLogin()])->assertOk();

        // A doctor who already has an account can't take a second one.
        $other = $this->postJson('/api/admin/doctor-accounts', [
            'doctor_id' => 8, 'phone' => '0597654321', 'password' => 'secret2', 'active' => 1, 'booking_enabled' => 1,
        ], $this->admin())->assertCreated()->json('id');
        $move(8)->assertStatus(422)->assertJsonValidationErrors('doctor_id');
        $this->assertSame(7, (int) DB::table('doctor_accounts')->where('id', $id)->value('doctor_id'));
        $this->assertSame(8, (int) DB::table('doctor_accounts')->where('id', $other)->value('doctor_id'));
    }

    public function test_doctor_and_admin_tokens_are_not_interchangeable()
    {
        $this->createAccount();
        $doctorToken = $this->doctorLogin();

        $this->getJson('/api/admin/me', ['Authorization' => "Bearer $doctorToken"])->assertStatus(401);
        $this->getJson('/api/doctor/me', ['Authorization' => 'Bearer ' . AdminToken::issue(1)])->assertStatus(401);
        $this->getJson('/api/doctor/me')->assertStatus(401);
    }

    public function test_a_doctor_deletes_their_own_account()
    {
        $this->createAccount();
        $token = $this->doctorLogin();
        $auth = ['Authorization' => "Bearer $token", 'Accept' => 'application/json'];

        $upcoming = $this->book()->assertCreated()->json('id');                                      // 2026-11-08
        $today = $this->book(['date' => '2026-11-07', 'time' => '09:00'])->assertCreated()->json('id');
        DB::table('doctor_appointments')->insert([
            ['doctor_id' => 6, 'code' => 'past', 'patient_name' => 'x', 'patient_phone' => '1', 'date' => '2026-11-01', 'time' => '09:00', 'status' => 'confirmed'],
            ['doctor_id' => 6, 'code' => 'done', 'patient_name' => 'x', 'patient_phone' => '1', 'date' => '2026-11-09', 'time' => '09:00', 'status' => 'completed'],
            ['doctor_id' => 7, 'code' => 'other', 'patient_name' => 'x', 'patient_phone' => '1', 'date' => '2026-11-08', 'time' => '09:00', 'status' => 'pending'],
        ]);

        // Needs the right password; nothing changes otherwise.
        $this->postJson('/api/doctor/account/delete', [], $auth)->assertStatus(422)->assertJsonValidationErrors(['password']);
        $this->postJson('/api/doctor/account/delete', ['password' => 'wrong'], $auth)->assertStatus(422)->assertJsonValidationErrors(['password']);
        $this->assertSame(1, DB::table('doctor_accounts')->count());
        $this->postJson('/api/doctor/account/delete', ['password' => 'secret1'])->assertStatus(401);

        $this->postJson('/api/doctor/account/delete', ['password' => 'secret1'], $auth)
            ->assertOk()->assertJson(['deleted' => true, 'cancelled_appointments' => 2]);

        $this->assertSame(0, DB::table('doctor_accounts')->count());
        $status = fn ($where) => DB::table('doctor_appointments')->where($where)->value('status');
        $this->assertSame('cancelled', $status(['id' => $upcoming]));
        $this->assertSame('cancelled', $status(['id' => $today]));
        $this->assertSame('confirmed', $status(['code' => 'past']), 'history stays as it was');
        $this->assertSame('completed', $status(['code' => 'done']));
        $this->assertSame('pending', $status(['code' => 'other']), "another doctor's bookings are untouched");
        $this->assertSame('د. علاء', DB::table('doctors')->where('id', 6)->value('name'), 'the directory page stays');

        // Signed out everywhere, and the number no longer signs in.
        $this->getJson('/api/doctor/me', $auth)->assertStatus(401);
        $this->postJson('/api/doctor/login', ['phone' => '0591234567', 'password' => 'secret1'])->assertStatus(401);
        // The doctor no longer takes bookings in the app.
        $this->assertSame([], \App\Services\Booking::enabledDoctorIds([6]));
    }
}
