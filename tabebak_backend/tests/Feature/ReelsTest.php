<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/** Reels: added from the dashboard (upload or link), listed in the app. */
class ReelsTest extends TestCase
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
        Schema::create('cities', function (Blueprint $t) {
            $t->id();
            $t->string('name');
        });
        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->text('description')->nullable();
            $t->string('mobile')->nullable();
            $t->string('address')->nullable();
            $t->unsignedBigInteger('category_id')->nullable();
            $t->unsignedBigInteger('city_id')->nullable();
        });
        $migrations = [...glob(database_path('migrations/2026_11_06_*.php')), database_path('migrations/2026_11_07_000001_create_reels_table.php')];
        foreach ($migrations as $file) {
            (require $file)->up();
        }

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('doctor_categories')->insert(['id' => 1, 'name' => 'الأسنان']);
        DB::table('cities')->insert(['id' => 3, 'name' => 'طولكرم']);
        DB::table('doctors')->insert(['id' => 6, 'name' => 'د. علاء', 'category_id' => 1, 'city_id' => 3, 'image' => 'doctors/a.jpg']);
    }

    private function admin(): array
    {
        return ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json'];
    }

    public function test_admin_adds_reels_by_upload_or_link()
    {
        // Upload.
        $row = $this->post('/api/admin/reels', [
            'title' => 'نصائح لصحة الأسنان',
            'video' => UploadedFile::fake()->create('clip.mp4', 900, 'video/mp4'),
            'thumbnail' => UploadedFile::fake()->image('cover.jpg'),
            'doctor_id' => 6,
            'active' => 1,
        ], $this->admin())->assertCreated()->json();
        $this->assertStringStartsWith('http://localhost/storage/reels/', $row['video']);
        Storage::disk('public')->assertExists(DB::table('reels')->value('video'));

        // Link.
        $this->post('/api/admin/reels', [
            'title' => 'رابط', 'video_url' => 'https://cdn.example.com/a.mp4', 'active' => 1,
        ], $this->admin())->assertCreated();

        // Neither, a bad link, a non-video and a too-big file are refused.
        $this->post('/api/admin/reels', ['title' => 'بدون فيديو'], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['video']);
        $this->post('/api/admin/reels', ['title' => 'x', 'video_url' => 'not a link'], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['video_url']);
        $this->post('/api/admin/reels', ['title' => 'x', 'video' => UploadedFile::fake()->create('a.pdf', 10, 'application/pdf')], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['video']);
        $this->post('/api/admin/reels', ['title' => 'x', 'video' => UploadedFile::fake()->create('big.mp4', 101 * 1024, 'video/mp4')], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['video']);

        // Editing the title keeps the uploaded video; removing it without a link is refused.
        $this->post("/api/admin/reels/{$row['id']}", ['_method' => 'PUT', 'title' => 'جديد', 'active' => 1], $this->admin())
            ->assertOk()->assertJsonPath('video', $row['video']);
        $this->post("/api/admin/reels/{$row['id']}", ['_method' => 'PUT', 'title' => 'جديد', 'video__remove' => 1, 'video_url' => ''], $this->admin())
            ->assertStatus(422);
    }

    public function test_app_lists_active_reels_with_their_doctor()
    {
        DB::table('doctor_accounts')->insert(['doctor_id' => 6, 'phone' => '0591234567', 'password' => 'x']);
        DB::table('reels')->insert([
            ['id' => 1, 'title' => 'أول', 'video' => 'reels/a.mp4', 'video_url' => null, 'thumbnail' => 'reels/a.jpg', 'doctor_id' => 6, 'active' => 1],
            ['id' => 2, 'title' => 'مخفي', 'video' => null, 'video_url' => 'https://x/b.mp4', 'thumbnail' => null, 'doctor_id' => null, 'active' => 0],
            ['id' => 3, 'title' => 'رابط', 'video' => null, 'video_url' => 'https://x/c.mp4', 'thumbnail' => null, 'doctor_id' => null, 'active' => 1],
        ]);

        $res = $this->getJson('/api/reels')->assertOk()->json();
        $this->assertSame([3, 1], array_column($res['data'], 'id')); // newest first, inactive hidden
        $this->assertSame('https://x/c.mp4', $res['data'][0]['video']);
        $this->assertNull($res['data'][0]['doctor']);

        $reel = $res['data'][1];
        $this->assertSame('http://localhost/storage/reels/a.mp4', $reel['video']);
        $this->assertSame('http://localhost/storage/reels/a.jpg', $reel['thumbnail']);
        $this->assertSame('د. علاء', $reel['doctor']['name']);
        $this->assertSame('الأسنان', $reel['doctor']['category']['name']);
        $this->assertSame('طولكرم', $reel['doctor']['city']['name']);
        $this->assertTrue($reel['doctor']['booking_enabled']);

        $this->postJson('/api/reels/1/view')->assertNoContent();
        $this->postJson('/api/reels/1/view');
        $this->assertSame(2, (int) DB::table('reels')->where('id', 1)->value('views'));
    }
}
