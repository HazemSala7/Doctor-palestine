<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** The first page of jobs feeds the home banner: chosen jobs, then the newest. */
class JobsOrderTest extends TestCase
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
        Schema::create('cities', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->timestamps();
        });
        Schema::create('jobs', function (Blueprint $t) {
            $t->id();
            $t->string('title');
            $t->string('type')->nullable();
            $t->string('location')->nullable();
            $t->text('description')->nullable();
            $t->unsignedBigInteger('city_id')->nullable();
            $t->timestamps();
        });
        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('cities')->insert(['id' => 1, 'name' => 'الخليل']);
        foreach ([1, 2, 3, 4] as $id) {
            DB::table('jobs')->insert(['id' => $id, 'title' => "job$id", 'type' => 'full-time', 'city_id' => 1]);
        }
    }

    private function migrate(): void
    {
        (require database_path('migrations/2026_11_07_000008_add_featured_to_jobs.php'))->up();
    }

    private function order(string $query = ''): array
    {
        return array_column($this->getJson('/api/jobs' . $query)->assertOk()->json('data'), 'id');
    }

    public function test_newest_first_even_before_the_migration_has_run()
    {
        $this->assertSame([4, 3, 2, 1], $this->order());
    }

    public function test_jobs_chosen_on_the_dashboard_come_first()
    {
        $this->migrate();
        $this->assertSame([4, 3, 2, 1], $this->order());

        $this->postJson('/api/admin/jobs/2', [
            '_method' => 'PUT', 'title' => 'job2', 'type' => 'full-time', 'city_id' => 1, 'featured' => 1,
        ], ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json'])->assertOk();

        $this->assertSame([2, 4, 3, 1], $this->order());
        $this->assertEquals(1, $this->getJson('/api/jobs')->json('data.0.featured'));
        $this->assertSame([2, 4, 3, 1], $this->order('?city_id=1'));
        $this->assertSame([], $this->order('?city_id=9'));
    }

    private function saveMobile(?string $mobile)
    {
        return $this->postJson('/api/admin/jobs/4', [
            '_method' => 'PUT', 'title' => 'job4', 'type' => 'full-time', 'city_id' => 1, 'mobile' => $mobile,
        ], ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json']);
    }

    public function test_saving_a_job_works_before_the_contact_number_migration_has_run()
    {
        $this->saveMobile('0591234567')->assertOk();
        $this->assertArrayNotHasKey('mobile', $this->getJson('/api/jobs')->json('data.0'));
    }

    public function test_the_contact_number_reaches_the_app_and_can_be_cleared()
    {
        (require database_path('migrations/2026_11_09_000001_add_mobile_to_jobs.php'))->up();

        $this->saveMobile('059-123 4567')->assertOk();
        $this->assertSame('059-123 4567', $this->getJson('/api/jobs')->json('data.0.mobile'));

        $this->saveMobile('+970 59 123 4567')->assertOk();
        $this->assertSame('+970 59 123 4567', $this->getJson('/api/jobs')->json('data.0.mobile'));

        $this->saveMobile('')->assertOk();
        $this->assertNull($this->getJson('/api/jobs')->json('data.0.mobile'));
    }

    public function test_a_number_that_cannot_be_dialled_is_refused()
    {
        (require database_path('migrations/2026_11_09_000001_add_mobile_to_jobs.php'))->up();

        foreach (['abc', '123', '------------', '٠٥٩١٢٣٤٥٦٧', str_repeat('1', 16), '059' . str_repeat(' ', 40) . '1234567'] as $bad) {
            $this->saveMobile($bad)->assertStatus(422)->assertJsonPath('errors.mobile.0', 'رقم الهاتف غير صحيح، مثال: 0591234567');
        }
        $this->assertNull($this->getJson('/api/jobs')->json('data.0.mobile'));
    }
}
