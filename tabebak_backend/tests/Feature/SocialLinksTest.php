<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** Facebook / Instagram links on doctors and centres, entered on the dashboard. */
class SocialLinksTest extends TestCase
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
            $t->string('email');
            $t->string('password');
        });
        // No `coordinates` column: SQLite has no spatial functions.
        Schema::create('pharmacies', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->unsignedBigInteger('city_id')->nullable();
            $t->timestamps();
        });
        (require database_path('migrations/2026_11_07_000004_add_social_links.php'))->up();
        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
    }

    private function save(array $links)
    {
        return $this->postJson('/api/admin/pharmacies', ['name' => 'صيدلية', 'city_id' => 1] + $links,
            ['Authorization' => 'Bearer ' . AdminToken::issue(1)]);
    }

    public function test_links_are_completed_and_validated()
    {
        $this->assertTrue(Schema::hasColumns('pharmacies', ['facebook_url', 'instagram_url']));

        $cases = [
            ['@tabebak', 'tabebak.ps', 'https://www.instagram.com/tabebak', 'https://www.facebook.com/tabebak.ps'],
            ['instagram.com/tabebak', 'fb.me/tabebak', 'https://instagram.com/tabebak', 'https://fb.me/tabebak'],
            ['https://www.instagram.com/x?igsh=1', 'https://facebook.com/profile.php?id=5', 'https://www.instagram.com/x?igsh=1', 'https://facebook.com/profile.php?id=5'],
        ];
        foreach ($cases as [$ig, $fb, $igOut, $fbOut]) {
            $row = $this->save(['instagram_url' => $ig, 'facebook_url' => $fb])->assertCreated()->json();
            $this->assertSame($igOut, $row['instagram_url']);
            $this->assertSame($fbOut, $row['facebook_url']);
        }

        // Empty is fine; a broken value is refused.
        $this->assertNull($this->save(['instagram_url' => '', 'facebook_url' => ''])->assertCreated()->json('instagram_url'));
        $this->save(['instagram_url' => 'https://exa mple'])->assertStatus(422)->assertJsonValidationErrors(['instagram_url']);
    }
}
