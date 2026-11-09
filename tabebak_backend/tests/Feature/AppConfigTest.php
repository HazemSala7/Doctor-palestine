<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** Dashboard-managed settings, counts and running ads served to the app. */
class AppConfigTest extends TestCase
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
        Carbon::setTestNow(Carbon::create(2026, 11, 7, 10, 0, 0, 'Asia/Hebron'));

        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email');
            $t->string('password');
        });
        Schema::create('cities', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->timestamps();
        });
        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->unsignedBigInteger('category_id')->nullable();
            $t->unsignedBigInteger('city_id')->nullable();
        });
        Schema::create('pharmacies', function (Blueprint $t) {
            $t->id();
            $t->string('name');
        });
        Schema::create('jobs', function (Blueprint $t) {
            $t->id();
            $t->string('title');
            $t->unsignedBigInteger('city_id')->nullable();
            $t->timestamps();
        });
        Schema::create('advertisements', function (Blueprint $t) {
            $t->id();
            $t->string('title');
            $t->string('image')->nullable();
            $t->string('type')->nullable();
            $t->string('target_id')->nullable();
            $t->boolean('active')->default(1);
            $t->date('start_date')->nullable();
            $t->date('end_date')->nullable();
            $t->timestamps();
        });
        foreach (glob(database_path('migrations/2026_11_07_00000[235]_*.php')) as $file) {
            (require $file)->up();
        }

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('cities')->insert([['id' => 1, 'name' => 'الخليل'], ['id' => 3, 'name' => 'طولكرم']]);
        DB::table('doctors')->insert([
            ['id' => 1, 'name' => 'أ', 'category_id' => 1, 'city_id' => 1],
            ['id' => 2, 'name' => 'ب', 'category_id' => 1, 'city_id' => 3],
            ['id' => 3, 'name' => 'ج', 'category_id' => 2, 'city_id' => 3],
        ]);
        DB::table('pharmacies')->insert([['name' => 'ص1'], ['name' => 'ص2']]);
        DB::table('jobs')->insert(['id' => 5, 'title' => 'ممرض', 'city_id' => 3]);
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

    public function test_flags_are_added_with_defaults()
    {
        $this->assertSame(0, (int) DB::table('doctors')->value('featured'));
        $this->assertSame(0, (int) DB::table('pharmacies')->value('on_duty'));
    }

    public function test_admin_edits_settings_and_the_app_reads_them()
    {
        $settings = $this->getJson('/api/admin/settings', $this->admin())->assertOk()->json();
        $this->assertSame('دليلك الطبي الشامل في فلسطين', $settings['tagline']);
        $this->assertStringContainsString('طبيبك', $settings['about_us']);
        $this->getJson('/api/admin/settings')->assertStatus(401);

        $this->putJson('/api/admin/settings', [
            'tagline' => 'طبيبك أقرب',
            'support_whatsapp' => '0599111222',
            'instagram_url' => 'https://instagram.com/tabebak',
            'unknown_key' => 'ignored',
        ], $this->admin())->assertOk()->assertJsonPath('tagline', 'طبيبك أقرب');
        $this->putJson('/api/admin/settings', ['facebook_url' => 'nope', 'support_email' => 'x'], $this->admin())
            ->assertStatus(422)->assertJsonValidationErrors(['facebook_url', 'support_email']);

        $config = $this->getJson('/api/app-config')->assertOk()->json();
        $this->assertSame('طبيبك أقرب', $config['settings']['tagline']);
        $this->assertSame('0599111222', $config['settings']['support_whatsapp']);
        $this->assertSame('https://instagram.com/tabebak', $config['settings']['instagram_url']);
        $this->assertArrayNotHasKey('unknown_key', $config['settings']);
        // Untouched keys keep their seeded value.
        $this->assertStringContainsString('خصوصيتك', $config['settings']['privacy_policy']);
    }

    public function test_app_config_counts_and_running_ads()
    {
        DB::table('advertisements')->insert([
            ['title' => 'يعمل', 'image' => 'advertisements/a.jpg', 'type' => 'job', 'target_id' => '5', 'active' => 1, 'start_date' => '2026-11-01', 'end_date' => '2026-11-30'],
            ['title' => 'متوقف', 'image' => 'x.jpg', 'type' => 'job', 'target_id' => '5', 'active' => 0, 'start_date' => null, 'end_date' => null],
            ['title' => 'انتهى', 'image' => 'x.jpg', 'type' => 'job', 'target_id' => '5', 'active' => 1, 'start_date' => null, 'end_date' => '2026-11-06'],
            ['title' => 'لم يبدأ', 'image' => 'x.jpg', 'type' => 'job', 'target_id' => '5', 'active' => 1, 'start_date' => '2026-11-08', 'end_date' => null],
            ['title' => 'بلا هدف', 'image' => 'https://cdn/x.jpg', 'type' => null, 'target_id' => null, 'active' => 1, 'start_date' => null, 'end_date' => null],
        ]);

        $config = $this->getJson('/api/app-config')->assertOk()->json();
        $this->assertSame(3, $config['counts']['doctors']);
        $this->assertSame(2, $config['counts']['pharmacies']);
        $this->assertSame(2, $config['counts']['cities']);
        $this->assertSame(0, $config['counts']['hospitals']); // table missing here
        $this->assertSame(['1' => 1, '3' => 2], $config['doctors_by_city']);
        $this->assertSame(['1' => 2, '2' => 1], $config['doctors_by_category']);

        $this->assertSame(['بلا هدف', 'يعمل'], array_column($config['advertisements'], 'title'));
        $ad = $config['advertisements'][1];
        $this->assertSame('http://localhost/storage/advertisements/a.jpg', $ad['image']);
        $this->assertSame('ممرض', $ad['target']['title']);
        $this->assertSame('طولكرم', $ad['target']['city']['name']);
        $this->assertNull($config['advertisements'][0]['target']);
        $this->assertSame('https://cdn/x.jpg', $config['advertisements'][0]['image']);
    }
}
