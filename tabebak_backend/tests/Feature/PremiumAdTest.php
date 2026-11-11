<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/** Premium ads: a full-screen window in the app plus a pinned, sponsored listing. */
class PremiumAdTest extends TestCase
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
        Storage::fake('public');
        // The Doctor model reads coordinates with MySQL's ST_AsText.
        DB::connection()->getPdo()->sqliteCreateFunction('ST_AsText', fn ($v) => $v, 1);

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
        Schema::create('doctor_categories', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->timestamps();
        });
        Schema::create('doctors', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('image')->nullable();
            $t->text('coordinates')->nullable();
            $t->unsignedBigInteger('category_id')->nullable();
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
        (require database_path('migrations/2026_11_07_000005_add_placement_to_advertisements.php'))->up();

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('cities')->insert(['id' => 3, 'name' => 'طولكرم']);
        DB::table('doctor_categories')->insert(['id' => 1, 'name' => 'الأسنان']);
        DB::table('doctors')->insert(['id' => 6, 'name' => 'د. علاء', 'category_id' => 1, 'city_id' => 3, 'coordinates' => 'POINT(35.0 32.3)']);
    }

    private function create(array $fields)
    {
        return $this->post('/api/admin/advertisements', $fields + [
            'title' => 'عرض', 'image' => UploadedFile::fake()->image('ad.jpg'), 'active' => 1,
        ], ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json']);
    }

    public function test_premium_ads_need_a_doctor_or_centre_and_come_first()
    {
        $this->create(['placement' => 'premium'])->assertStatus(422)->assertJsonValidationErrors(['type']);
        $this->create(['placement' => 'premium', 'type' => 'job', 'target_id' => 1])->assertStatus(422);
        $this->create(['placement' => 'gold'])->assertStatus(422)->assertJsonValidationErrors(['placement']);

        $this->create(['title' => 'عادي', 'placement' => 'banner'])->assertCreated();
        $this->create([
            'title' => 'ابتسامة هوليوود', 'placement' => 'premium', 'type' => 'doctor', 'target_id' => 6,
            'description' => 'خصم 20٪ على تبييض الأسنان هذا الشهر',
        ])->assertCreated();

        $ads = $this->getJson('/api/app-config')->assertOk()->json('advertisements');
        $this->assertSame(['ابتسامة هوليوود', 'عادي'], array_column($ads, 'title'));
        $this->assertSame('premium', $ads[0]['placement']);
        $this->assertSame('خصم 20٪ على تبييض الأسنان هذا الشهر', $ads[0]['description']);
        $this->assertSame('د. علاء', $ads[0]['target']['name']);
        $this->assertSame('الأسنان', $ads[0]['target']['category']['name']);
        $this->assertSame('banner', $ads[1]['placement']);
    }

    public function test_vip_ads_need_a_doctor_or_centre_and_lead_even_past_the_limit()
    {
        $this->create(['placement' => 'vip'])->assertStatus(422)->assertJsonValidationErrors(['type']);
        $this->create(['placement' => 'vip', 'type' => 'city', 'target_id' => 3])->assertStatus(422);

        $this->create(['title' => 'نخبة', 'placement' => 'vip', 'type' => 'doctor', 'target_id' => 6])->assertCreated();
        $this->create(['title' => 'مميز', 'placement' => 'premium', 'type' => 'doctor', 'target_id' => 6])->assertCreated();
        for ($i = 1; $i <= 12; $i++) {
            $this->create(['title' => "عادي $i", 'placement' => 'banner'])->assertCreated();
        }

        $ads = $this->getJson('/api/app-config')->assertOk()->json('advertisements');
        $this->assertCount(10, $ads);
        $this->assertSame(['vip', 'premium', 'banner'], array_slice(array_column($ads, 'placement'), 0, 3));
        $this->assertSame('نخبة', $ads[0]['title']);
        $this->assertSame('د. علاء', $ads[0]['target']['name']);
        $this->assertSame('عادي 12', $ads[2]['title']);
        $this->assertFalse($ads[0]['target']['booking_enabled']);

        // Once the doctor takes bookings, the ad says so, so the app can offer "book".
        Schema::create('doctor_accounts', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('doctor_id');
            $t->boolean('active')->default(1);
            $t->boolean('booking_enabled')->default(0);
        });
        DB::table('doctor_accounts')->insert(['doctor_id' => 6, 'active' => 1, 'booking_enabled' => 1]);
        $ads = $this->getJson('/api/app-config')->assertOk()->json('advertisements');
        $this->assertTrue($ads[0]['target']['booking_enabled']);
    }
}
