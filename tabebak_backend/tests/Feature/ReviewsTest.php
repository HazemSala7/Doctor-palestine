<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use App\Services\AppSettings;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** Patients rate doctors and centres; the dashboard moderates; doctors reply. */
class ReviewsTest extends TestCase
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
        foreach (['doctors', 'laboratories'] as $table) {
            Schema::create($table, function (Blueprint $t) {
                $t->id();
                $t->string('name');
                $t->string('image')->nullable();
                $t->unsignedBigInteger('category_id')->nullable();
                $t->unsignedBigInteger('city_id')->nullable();
                $t->string('mobile')->nullable();
                $t->string('address')->nullable();
            });
        }
        foreach ([
            '2026_11_06_000001_create_doctor_accounts_table.php',
            '2026_11_06_000002_create_doctor_appointments_table.php',
            '2026_11_07_000002_create_app_settings_table.php',
            '2026_11_07_000006_create_reviews_table.php',
            '2026_11_07_000007_create_staff_members_table.php',
        ] as $file) {
            (require database_path('migrations/' . $file))->up();
        }

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('doctors')->insert([['id' => 6, 'name' => 'د. علاء'], ['id' => 7, 'name' => 'د. سارة']]);
        DB::table('laboratories')->insert(['id' => 3, 'name' => 'مختبر الشفاء']);
    }

    private function admin(): array
    {
        return ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json'];
    }

    private function review(array $over = [], string $path = 'doctor/6')
    {
        return $this->postJson("/api/reviews/$path", $over + [
            'name' => 'محمد', 'phone' => '0599 000 111', 'rating' => 4, 'comment' => 'طبيب ممتاز',
        ]);
    }

    private function approve(int $id, string $status = 'approved')
    {
        $row = DB::table('reviews')->where('id', $id)->first();

        return $this->postJson("/api/admin/reviews/$id", [
            '_method' => 'PUT', 'type' => $row->type, 'target_id' => $row->target_id, 'name' => $row->name,
            'phone' => $row->phone, 'rating' => $row->rating, 'comment' => $row->comment, 'status' => $status,
        ], $this->admin());
    }

    private function stored(string $table, int $id): array
    {
        $row = DB::table($table)->where('id', $id)->first();

        return [$row->rating_avg === null ? null : (float) $row->rating_avg, (int) $row->rating_count];
    }

    public function test_reviews_wait_for_approval_and_update_the_rating()
    {
        $this->assertTrue(Schema::hasColumns('laboratories', ['rating_avg', 'rating_count']));

        $res = $this->review()->assertCreated()->json();
        $this->assertSame('pending', $res['status']);
        $this->assertArrayNotHasKey('phone', $res['review']);
        $this->getJson('/api/reviews/doctor/6')->assertOk()->assertJson(['total' => 0, 'summary' => ['count' => 0, 'average' => null]]);
        $this->assertSame([null, 0], $this->stored('doctors', 6));

        // The dashboard sees the phone and the place's name, and approves.
        $row = $this->getJson('/api/admin/reviews', $this->admin())->assertOk()->json('data.0');
        $this->assertSame('0599000111', $row['phone']);
        $this->assertSame('د. علاء', $row['place_name']);
        $this->approve($row['id'])->assertOk();
        $this->review(['phone' => '0598 111 222', 'rating' => 1, 'comment' => ''])->assertCreated();
        $this->approve(DB::table('reviews')->max('id'))->assertOk();

        $page = $this->getJson('/api/reviews/doctor/6')->assertOk()->json();
        $this->assertSame(2, $page['total']);
        $this->assertSame(2.5, $page['summary']['average']);
        $this->assertSame(['5' => 0, '4' => 1, '3' => 0, '2' => 0, '1' => 1], $page['summary']['breakdown']);
        $this->assertNull($page['data'][0]['comment']); // newest first, empty comment stored as null
        $this->assertStringNotContainsString('0599000111', json_encode($page));
        $this->assertSame([2.5, 2], $this->stored('doctors', 6));
        $this->assertSame([null, 0], $this->stored('doctors', 7));

        // Writing again from the same phone replaces the review and needs approval again.
        $this->review(['rating' => 5])->assertOk()->assertJson(['updated' => true, 'status' => 'pending']);
        $this->assertSame(2, DB::table('reviews')->count());
        $this->assertSame([1.0, 1], $this->stored('doctors', 6));

        // Every dashboard change refreshes the stored rating. Review 1 is now 5 stars, review 2 is 1 star.
        $this->approve(1)->assertOk();
        $this->assertSame([3.0, 2], $this->stored('doctors', 6));
        $this->approve(2, 'rejected')->assertOk();
        $this->assertSame([5.0, 1], $this->stored('doctors', 6));
        $this->deleteJson('/api/admin/reviews/1', [], $this->admin())->assertNoContent();
        $this->assertSame([null, 0], $this->stored('doctors', 6));
        $this->approve(2)->assertOk();
        $this->assertSame([1.0, 1], $this->stored('doctors', 6));
        $this->postJson('/api/admin/reviews/bulk-delete', ['ids' => DB::table('reviews')->pluck('id')->all()], $this->admin())
            ->assertNoContent();
        $this->assertSame(0, DB::table('reviews')->count());
        $this->assertSame([null, 0], $this->stored('doctors', 6));
    }

    public function test_deleting_a_place_removes_its_reviews_team_and_login()
    {
        $review = fn (string $type, int $id, string $phone) => ['type' => $type, 'target_id' => $id, 'name' => 'x', 'phone' => $phone, 'rating' => 5, 'status' => 'approved'];
        $member = fn (string $type, int $id) => ['type' => $type, 'target_id' => $id, 'name' => 'x', 'role' => 'y'];
        DB::table('reviews')->insert([$review('doctor', 6, '0591'), $review('doctor', 7, '0592'), $review('lab', 3, '0593')]);
        // Same id as the deleted doctor, but a different kind of place.
        DB::table('reviews')->insert($review('lab', 6, '0594'));
        DB::table('staff_members')->insert([$member('doctor', 6), $member('doctor', 7), $member('lab', 3), $member('lab', 6)]);
        DB::table('doctor_accounts')->insert([
            ['doctor_id' => 6, 'phone' => '0599000006', 'password' => 'x'],
            ['doctor_id' => 7, 'phone' => '0599000007', 'password' => 'x'],
        ]);

        $this->deleteJson('/api/admin/doctors/6', [], $this->admin())->assertNoContent();

        $this->assertSame(0, DB::table('reviews')->where(['type' => 'doctor', 'target_id' => 6])->count());
        $this->assertSame(0, DB::table('staff_members')->where(['type' => 'doctor', 'target_id' => 6])->count());
        $this->assertSame([7], DB::table('doctor_accounts')->pluck('doctor_id')->map(fn ($v) => (int) $v)->all());
        $this->assertSame(1, DB::table('reviews')->where(['type' => 'lab', 'target_id' => 6])->count());
        $this->assertSame(1, DB::table('staff_members')->where(['type' => 'lab', 'target_id' => 6])->count());

        $this->postJson('/api/admin/laboratories/bulk-delete', ['ids' => [3]], $this->admin())->assertNoContent();
        $this->assertSame(0, DB::table('reviews')->where(['type' => 'lab', 'target_id' => 3])->count());
        $this->assertSame(0, DB::table('staff_members')->where(['type' => 'lab', 'target_id' => 3])->count());
        $this->assertSame(1, DB::table('reviews')->where(['type' => 'doctor', 'target_id' => 7])->count());
    }

    public function test_dashboard_place_forms_cannot_write_the_rating()
    {
        Schema::create('pharmacies', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->unsignedBigInteger('city_id')->nullable();
            $t->decimal('rating_avg', 3, 2)->nullable();
            $t->unsignedInteger('rating_count')->default(0);
        });
        $row = $this->postJson('/api/admin/pharmacies', ['name' => 'صيدلية', 'city_id' => 1, 'rating_avg' => 5, 'rating_count' => 900], $this->admin())
            ->assertCreated()->json();
        $this->assertNull($row['rating_avg']);
        $this->assertSame(0, (int) $row['rating_count']);
    }

    public function test_centres_validation_and_auto_approve()
    {
        $this->review([], 'lab/3')->assertCreated()->assertJson(['status' => 'pending']);
        $this->review([], 'lab/99')->assertNotFound();
        $this->review([], 'job/3')->assertNotFound();
        $this->review(['rating' => 6])->assertStatus(422)->assertJsonValidationErrors(['rating']);
        $this->review(['phone' => '12'])->assertStatus(422)->assertJsonValidationErrors(['phone']);
        $this->review(['name' => ''])->assertStatus(422)->assertJsonValidationErrors(['name']);

        AppSettings::save(['reviews_auto_approve' => '1']);
        $this->review(['phone' => '0597777777', 'rating' => 5], 'lab/3')->assertCreated()->assertJson(['status' => 'approved']);
        $this->assertSame([5.0, 1], $this->stored('laboratories', 3));
        $this->getJson('/api/reviews/lab/3')->assertOk()->assertJson(['total' => 1, 'summary' => ['average' => 5]]);

        // The dashboard must point a review at a real place.
        $this->postJson('/api/admin/reviews', [
            'type' => 'lab', 'target_id' => 404, 'name' => 'x', 'phone' => '0591111111', 'rating' => 3, 'status' => 'approved',
        ], $this->admin())->assertStatus(422)->assertJsonValidationErrors(['target_id']);
        $this->postJson('/api/admin/reviews', [
            'type' => 'lab', 'target_id' => 3, 'name' => 'x', 'phone' => '0597777777', 'rating' => 3, 'status' => 'approved',
        ], $this->admin())->assertStatus(422)->assertJsonValidationErrors(['phone']);
    }

    public function test_verified_reviews_and_doctor_replies()
    {
        $this->postJson('/api/admin/doctor-accounts', [
            'doctor_id' => 6, 'phone' => '0591234567', 'password' => 'secret1', 'active' => 1, 'booking_enabled' => 1,
        ], $this->admin())->assertCreated();
        DB::table('doctor_appointments')->insert([
            'doctor_id' => 6, 'code' => 'abc', 'patient_name' => 'محمد', 'patient_phone' => '0599000111',
            'date' => '2026-11-01', 'time' => '10:00', 'status' => 'confirmed',
        ]);
        AppSettings::save(['reviews_auto_approve' => '1']);

        $this->review(['appointment_code' => 'abc'])->assertStatus(422)->assertJsonValidationErrors(['appointment_code']);
        $this->review(['appointment_code' => 'abc'], 'doctor/7')->assertStatus(422)->assertJsonValidationErrors(['appointment_code']);
        DB::table('doctor_appointments')->update(['status' => 'completed']);
        $review = $this->review(['appointment_code' => 'abc'])->assertCreated()->json('review');
        $this->assertTrue($review['verified']);
        $other = $this->review(['phone' => '0590000001'], 'doctor/7')->assertCreated()->json('review');

        $token = $this->postJson('/api/doctor/login', ['phone' => '0591234567', 'password' => 'secret1'])->assertOk()->json('token');
        $auth = ['Authorization' => "Bearer $token"];
        $mine = $this->getJson('/api/doctor/reviews', $auth)->assertOk()->json();
        $this->assertSame(1, $mine['total']);
        $this->assertSame(4, $mine['summary']['average'] * 1);

        $this->postJson("/api/doctor/reviews/{$review['id']}/reply", ['reply' => 'شكراً لك، نتمنى لك الصحة'], $auth)
            ->assertOk()->assertJson(['reply' => 'شكراً لك، نتمنى لك الصحة']);
        $this->postJson("/api/doctor/reviews/{$other['id']}/reply", ['reply' => 'x'], $auth)->assertNotFound();
        $public = $this->getJson('/api/reviews/doctor/6')->json('data.0');
        $this->assertSame('شكراً لك، نتمنى لك الصحة', $public['reply']);
        $this->assertNotNull($public['replied_at']);
        $this->getJson('/api/doctor/reviews')->assertUnauthorized();

        // Editing the review drops the old reply; it stays verified.
        $edited = $this->review(['rating' => 2])->assertOk()->json('review');
        $this->assertNull($edited['reply']);
        $this->assertTrue($edited['verified']);
        $this->postJson("/api/doctor/reviews/{$review['id']}/reply", ['reply' => ''], $auth)->assertOk()->assertJson(['reply' => null]);
    }
}
