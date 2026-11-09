<?php

namespace Tests\Feature;

use App\Http\Middleware\DoctorToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/** A doctor manages their own page and team from the app, and nobody else's. */
class DoctorPageTest extends TestCase
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
        DB::connection()->getPdo()->sqliteCreateFunction('ST_AsText', fn ($v) => $v, 1);
        DB::connection()->getPdo()->sqliteCreateFunction('ST_GeomFromText', fn ($v) => $v, 1);

        foreach (['cities', 'doctor_categories'] as $table) {
            Schema::create($table, function (Blueprint $t) {
                $t->id();
                $t->string('name');
                $t->timestamps();
            });
        }
        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->unsignedBigInteger('category_id')->nullable();
            $t->unsignedBigInteger('city_id')->nullable();
            $t->string('mobile')->nullable();
            $t->string('address')->nullable();
            $t->text('description')->nullable();
            $t->string('facebook_url')->nullable();
            $t->string('instagram_url')->nullable();
            $t->boolean('featured')->default(false);
            $t->decimal('rating_avg', 3, 2)->nullable();
            $t->unsignedInteger('rating_count')->default(0);
            $t->text('coordinates')->nullable();
            $t->timestamps();
        });
        foreach ([
            '2026_11_06_000001_create_doctor_accounts_table.php',
            '2026_11_07_000007_create_staff_members_table.php',
            '2026_11_07_000001_create_reels_table.php',
        ] as $file) {
            (require database_path('migrations/' . $file))->up();
        }

        DB::table('cities')->insert([['id' => 1, 'name' => 'الخليل'], ['id' => 2, 'name' => 'رام الله']]);
        DB::table('doctor_categories')->insert([['id' => 2, 'name' => 'باطني'], ['id' => 3, 'name' => 'أسنان']]);
        DB::table('doctors')->insert([
            ['id' => 6, 'name' => 'د. علاء', 'city_id' => 1, 'category_id' => 2],
            ['id' => 7, 'name' => 'د. سارة', 'city_id' => 1, 'category_id' => 2],
        ]);
        DB::table('doctor_accounts')->insert([
            ['id' => 1, 'doctor_id' => 6, 'phone' => '0591111111', 'password' => Hash::make('secret1'), 'active' => 1],
            ['id' => 2, 'doctor_id' => 7, 'phone' => '0592222222', 'password' => Hash::make('secret1'), 'active' => 1],
        ]);
    }

    private function auth(int $accountId = 1): array
    {
        return ['Authorization' => 'Bearer ' . DoctorToken::issue(DB::table('doctor_accounts')->find($accountId)), 'Accept' => 'application/json'];
    }

    private function page(array $over = []): array
    {
        return $over + ['name' => 'د. علاء الشيخ', 'category_id' => 3, 'city_id' => 2];
    }

    private function member(array $over = []): array
    {
        return $over + ['name' => 'سارة أحمد', 'role' => 'ممرضة', 'active' => 1];
    }

    private function addMember(int $account = 1, array $over = []): int
    {
        $this->postJson('/api/doctor/staff', $this->member($over), $this->auth($account))->assertCreated();

        return (int) DB::table('staff_members')->max('id');
    }

    private function addReel(int $account = 1, array $over = [])
    {
        Storage::fake('public');
        $this->post('/api/doctor/reels', $over + [
            'title' => 'نصائح للأسنان',
            'active' => 1,
            'video' => UploadedFile::fake()->create('clip.mp4', 900, 'video/mp4'),
        ], $this->auth($account))->assertCreated();

        return DB::table('reels')->orderByDesc('id')->first();
    }

    public function test_a_doctor_adds_a_reel_and_patients_see_it()
    {
        $reel = $this->addReel(1, ['description' => 'وصف', 'thumbnail' => UploadedFile::fake()->image('cover.jpg')]);

        $this->assertEquals(6, $reel->doctor_id);
        Storage::disk('public')->assertExists($reel->video);
        Storage::disk('public')->assertExists($reel->thumbnail);

        $this->getJson('/api/doctor/reels', $this->auth())->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'نصائح للأسنان')
            ->assertJsonPath('data.0.active', true);
        $this->getJson('/api/doctor/reels', $this->auth(2))->assertOk()->assertJsonCount(0, 'data');

        $this->getJson('/api/reels')->assertOk()
            ->assertJsonPath('data.0.title', 'نصائح للأسنان')
            ->assertJsonPath('data.0.doctor.id', 6);
    }

    public function test_a_reel_needs_a_title_and_a_real_video()
    {
        Storage::fake('public');
        $this->post('/api/doctor/reels', ['title' => 'بلا فيديو'], $this->auth())
            ->assertStatus(422)->assertJsonValidationErrors('video');
        $this->post('/api/doctor/reels', ['video' => UploadedFile::fake()->create('clip.mp4', 10, 'video/mp4')], $this->auth())
            ->assertStatus(422)->assertJsonPath('errors.title.0', 'عنوان الفيديو مطلوب');
        $this->post('/api/doctor/reels', ['title' => 'x', 'video' => UploadedFile::fake()->create('a.pdf', 10, 'application/pdf')], $this->auth())
            ->assertStatus(422)->assertJsonValidationErrors('video');
        $this->post('/api/doctor/reels', ['title' => 'x', 'video' => UploadedFile::fake()->create('big.mp4', 101 * 1024, 'video/mp4')], $this->auth())
            ->assertStatus(422)->assertJsonValidationErrors('video');
        $this->assertSame(0, DB::table('reels')->count());
    }

    public function test_editing_a_reel_keeps_its_video_and_can_hide_it()
    {
        $reel = $this->addReel(1, ['thumbnail' => UploadedFile::fake()->image('cover.jpg')]);

        $this->post("/api/doctor/reels/{$reel->id}", [
            'title' => 'عنوان جديد', 'active' => 0, 'thumbnail__remove' => 1,
        ], $this->auth())->assertOk();

        $after = DB::table('reels')->find($reel->id);
        $this->assertSame('عنوان جديد', $after->title);
        $this->assertSame($reel->video, $after->video);
        $this->assertNull($after->thumbnail);
        $this->getJson('/api/reels')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/doctor/reels', $this->auth())->assertJsonPath('data.0.active', false);

        $this->post("/api/doctor/reels/{$reel->id}", [
            'title' => 'عنوان جديد', 'active' => 1,
            'video' => UploadedFile::fake()->create('new.mp4', 500, 'video/mp4'),
        ], $this->auth())->assertOk();
        $this->assertNotSame($reel->video, DB::table('reels')->find($reel->id)->video);
    }

    public function test_a_doctor_cannot_touch_another_doctors_reel_or_its_counters()
    {
        $reel = $this->addReel(1);
        DB::table('reels')->where('id', $reel->id)->update(['views' => 40]);

        $this->post("/api/doctor/reels/{$reel->id}", ['title' => 'سرقة'], $this->auth(2))->assertNotFound();
        $this->post("/api/doctor/reels/{$reel->id}/delete", [], $this->auth(2))->assertNotFound();

        $this->post("/api/doctor/reels/{$reel->id}?doctor_id=7", [
            'title' => 'تعديل', 'doctor_id' => 7, 'views' => 9999, 'video_url' => 'https://evil.example/a.mp4',
        ], $this->auth())->assertOk();
        $after = DB::table('reels')->find($reel->id);
        $this->assertEquals(6, $after->doctor_id);
        $this->assertEquals(40, $after->views);
        $this->assertNull($after->video_url);
    }

    public function test_a_doctor_deletes_their_reel()
    {
        $reel = $this->addReel(1);
        $this->post("/api/doctor/reels/{$reel->id}/delete", [], $this->auth())->assertNoContent();
        $this->assertSame(0, DB::table('reels')->count());
    }

    public function test_everything_needs_a_signed_in_doctor()
    {
        $this->getJson('/api/doctor/reels')->assertStatus(401);
        $this->postJson('/api/doctor/reels', ['title' => 'x'])->assertStatus(401);
        $this->getJson('/api/doctor/page')->assertStatus(401);
        $this->postJson('/api/doctor/page', $this->page())->assertStatus(401);
        $this->postJson('/api/doctor/staff', $this->member())->assertStatus(401);
    }

    public function test_the_doctor_loads_their_own_details_and_choices()
    {
        $this->getJson('/api/doctor/page', $this->auth())->assertOk()
            ->assertJsonPath('doctor.name', 'د. علاء')
            ->assertJsonCount(2, 'cities')
            ->assertJsonCount(2, 'categories');
    }

    public function test_saved_details_reach_the_public_page()
    {
        $this->postJson('/api/doctor/page', $this->page([
            'mobile' => '059-123 4567',
            'address' => 'شارع عين سارة',
            'description' => 'طبيب أسنان',
            'facebook_url' => '@dr.alaa',
            'coordinates' => json_encode([['lat' => '31.5', 'lng' => '35.1']]),
        ]), $this->auth())->assertOk();

        $row = collect($this->getJson('/api/doctors')->assertOk()->json('data'))->firstWhere('id', 6);
        $this->assertSame('د. علاء الشيخ', $row['name']);
        $this->assertEquals(3, $row['category_id']);
        $this->assertEquals(2, $row['city_id']);
        $this->assertSame('059-123 4567', $row['mobile']);
        $this->assertSame('شارع عين سارة', $row['address']);
        $this->assertSame('https://www.facebook.com/dr.alaa', $row['facebook_url']);
        $this->assertSame('د. سارة', DB::table('doctors')->find(7)->name);
    }

    public function test_a_doctor_cannot_change_what_only_the_admin_controls()
    {
        DB::table('doctors')->where('id', 6)->update(['rating_avg' => 4.5, 'rating_count' => 8]);

        $this->postJson('/api/doctor/page?featured=1&id=7', $this->page([
            'featured' => 1, 'rating_avg' => 5, 'rating_count' => 99, 'id' => 7,
        ]), $this->auth())->assertOk();

        $me = DB::table('doctors')->find(6);
        $this->assertEquals(0, $me->featured);
        $this->assertEquals(4.5, $me->rating_avg);
        $this->assertEquals(8, $me->rating_count);
        $this->assertSame('د. سارة', DB::table('doctors')->find(7)->name);
    }

    public function test_bad_details_get_a_clear_message()
    {
        $res = $this->postJson('/api/doctor/page', ['name' => '', 'category_id' => 99, 'city_id' => 99, 'mobile' => 'abc'], $this->auth())->assertStatus(422);
        $this->assertSame('الاسم مطلوب', $res->json('errors.name.0'));
        $this->assertSame('اختر التخصص', $res->json('errors.category_id.0'));
        $this->assertSame('اختر المدينة', $res->json('errors.city_id.0'));
        $this->assertSame('رقم الهاتف غير صحيح، مثال: 0591234567', $res->json('errors.mobile.0'));
    }

    public function test_the_photo_can_be_changed_and_removed()
    {
        Storage::fake('public');
        $auth = $this->auth();

        $this->post('/api/doctor/page', $this->page(['image' => UploadedFile::fake()->image('a.jpg')]), $auth)->assertOk();
        $path = DB::table('doctors')->find(6)->image;
        $this->assertNotEmpty($path);
        Storage::disk('public')->assertExists($path);
        $this->assertStringContainsString('/storage/', $this->getJson('/api/doctor/page', $auth)->json('doctor.image'));

        $this->post('/api/doctor/page', $this->page(), $auth)->assertOk();
        $this->assertSame($path, DB::table('doctors')->find(6)->image);

        $this->post('/api/doctor/page', $this->page(['image__remove' => 1]), $auth)->assertOk();
        $this->assertNull(DB::table('doctors')->find(6)->image);
    }

    public function test_the_doctor_manages_the_team_and_patients_see_it()
    {
        $id = $this->addMember(1, ['bio' => 'خبرة 5 سنوات']);
        $row = DB::table('staff_members')->find($id);
        $this->assertSame('doctor', $row->type);
        $this->assertEquals(6, $row->target_id);
        $this->getJson('/api/staff/doctor/6')->assertOk()->assertJsonPath('data.0.name', 'سارة أحمد');

        $this->postJson("/api/doctor/staff/$id", $this->member(['name' => 'سارة خليل', 'role' => 'سكرتيرة']), $this->auth())->assertOk();
        $this->getJson('/api/staff/doctor/6')->assertJsonPath('data.0.name', 'سارة خليل')->assertJsonPath('data.0.role', 'سكرتيرة');

        $this->postJson("/api/doctor/staff/$id", $this->member(['name' => 'سارة خليل', 'active' => 0]), $this->auth())->assertOk();
        $this->getJson('/api/staff/doctor/6')->assertJsonCount(0, 'data');
        $this->getJson('/api/doctor/staff', $this->auth())->assertJsonCount(1, 'data')->assertJsonPath('data.0.active', false);

        $this->postJson("/api/doctor/staff/$id/delete", [], $this->auth())->assertNoContent();
        $this->assertNull(DB::table('staff_members')->find($id));
    }

    public function test_a_new_member_goes_last_and_the_order_can_be_changed()
    {
        $a = $this->addMember(1, ['name' => 'أ']);
        $b = $this->addMember(1, ['name' => 'ب']);
        $c = $this->addMember(1, ['name' => 'ج']);
        $this->assertSame([$a, $b, $c], array_column($this->getJson('/api/doctor/staff', $this->auth())->json('data'), 'id'));

        $this->postJson('/api/doctor/staff/reorder', ['ids' => [$c, $a, $b]], $this->auth())->assertOk();
        $this->assertSame([$c, $a, $b], array_column($this->getJson('/api/staff/doctor/6')->json('data'), 'id'));
    }

    public function test_a_doctor_cannot_touch_another_doctors_team()
    {
        $theirs = $this->addMember(2, ['name' => 'موظف د. سارة']);
        $mine = $this->addMember(1);

        $this->postJson("/api/doctor/staff/$theirs", $this->member(['name' => 'تغيير']), $this->auth(1))->assertStatus(404);
        $this->postJson("/api/doctor/staff/$theirs/delete", [], $this->auth(1))->assertStatus(404);
        $this->postJson('/api/doctor/staff/reorder', ['ids' => [$mine, $theirs]], $this->auth(1))->assertOk();

        $row = DB::table('staff_members')->find($theirs);
        $this->assertSame('موظف د. سارة', $row->name);
        $this->assertEquals(1, $row->sort_order);
        $this->getJson('/api/doctor/staff', $this->auth(1))->assertJsonCount(1, 'data');
    }

    public function test_a_member_cannot_be_moved_to_another_place_or_linked()
    {
        $id = $this->addMember();
        $this->postJson("/api/doctor/staff/$id", $this->member([
            'type' => 'doctor', 'target_id' => 7, 'doctor_id' => 7, 'sort_order' => 500,
        ]), $this->auth())->assertOk();

        $row = DB::table('staff_members')->find($id);
        $this->assertEquals(6, $row->target_id);
        $this->assertNull($row->doctor_id);
        $this->assertNotEquals(500, $row->sort_order);
    }

    public function test_a_member_needs_a_name_and_a_role()
    {
        $res = $this->postJson('/api/doctor/staff', ['name' => '', 'role' => ''], $this->auth())->assertStatus(422);
        $this->assertSame('الاسم مطلوب', $res->json('errors.name.0'));
        $this->assertSame('الوظيفة مطلوبة', $res->json('errors.role.0'));
        $this->postJson('/api/doctor/staff', $this->member(['name' => str_repeat('س', 81)]), $this->auth())->assertStatus(422);
    }
}
