<?php

namespace Tests\Feature;

use App\Http\Middleware\AdminToken;
use App\Services\StaffExamples;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/** The team on a doctor's or centre's page, managed on the dashboard. */
class StaffTest extends TestCase
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
        // The Doctor model reads coordinates with MySQL's ST_AsText.
        DB::connection()->getPdo()->sqliteCreateFunction('ST_AsText', fn ($v) => $v, 1);

        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email');
            $t->string('password');
        });
        foreach (['cities', 'doctor_categories'] as $table) {
            Schema::create($table, function (Blueprint $t) {
                $t->id();
                $t->string('name');
                $t->timestamps();
            });
        }
        foreach (['doctors', 'hospitals', 'laboratories'] as $table) {
            Schema::create($table, function (Blueprint $t) {
                $t->id();
                $t->string('name');
                $t->string('image')->nullable();
                $t->unsignedBigInteger('category_id')->nullable();
                $t->unsignedBigInteger('city_id')->nullable();
                $t->string('mobile')->nullable();
                $t->text('coordinates')->nullable();
                $t->timestamps();
            });
        }
        foreach ([
            '2026_11_06_000001_create_doctor_accounts_table.php',
            '2026_11_07_000007_create_staff_members_table.php',
        ] as $file) {
            (require database_path('migrations/' . $file))->up();
        }

        DB::table('users')->insert(['id' => 1, 'name' => 'Admin', 'email' => 'a@a.ps', 'password' => Hash::make('x')]);
        DB::table('cities')->insert(['id' => 1, 'name' => 'الخليل']);
        DB::table('doctor_categories')->insert(['id' => 2, 'name' => 'باطني']);
        DB::table('doctors')->insert(['id' => 6, 'name' => 'د. علاء', 'city_id' => 1, 'category_id' => 2, 'image' => 'doctors/a.jpg']);
        DB::table('hospitals')->insert([['id' => 4, 'name' => 'مستشفى الأهلي'], ['id' => 5, 'name' => 'مستشفى الميزان']]);
        DB::table('laboratories')->insert(['id' => 3, 'name' => 'مختبر الشفاء']);
    }

    private function admin(): array
    {
        return ['Authorization' => 'Bearer ' . AdminToken::issue(1), 'Accept' => 'application/json'];
    }

    public function test_dashboard_manages_the_team_and_the_app_lists_it()
    {
        $add = fn (array $row) => $this->postJson('/api/admin/staff', $row, $this->admin());

        $add(['type' => 'hospital', 'target_id' => 4, 'name' => 'ممرضة', 'role' => 'تمريض', 'sort_order' => 2])->assertCreated()
            ->assertJsonPath('place_name', 'مستشفى الأهلي');
        $add(['type' => 'hospital', 'target_id' => 4, 'name' => 'د. علاء', 'role' => 'رئيس قسم الباطني', 'doctor_id' => 6, 'sort_order' => 1])->assertCreated();
        $add(['type' => 'hospital', 'target_id' => 4, 'name' => 'مخفي', 'role' => 'إداري', 'active' => 0])->assertCreated();
        $add(['type' => 'hospital', 'target_id' => 5, 'name' => 'آخر', 'role' => 'فني'])->assertCreated();

        // Each place must exist, and so must a linked doctor.
        $add(['type' => 'hospital', 'target_id' => 99, 'name' => 'x', 'role' => 'y'])->assertStatus(422)->assertJsonValidationErrors('target_id');
        $add(['type' => 'job', 'target_id' => 1, 'name' => 'x', 'role' => 'y'])->assertStatus(422)->assertJsonValidationErrors('type');
        $add(['type' => 'lab', 'target_id' => 3, 'name' => 'x', 'role' => 'y', 'doctor_id' => 99])->assertStatus(422)->assertJsonValidationErrors('doctor_id');
        $add(['type' => 'lab', 'target_id' => 3, 'name' => 'x'])->assertStatus(422)->assertJsonValidationErrors('role');

        $res = $this->getJson('/api/staff/hospital/4')->assertOk();
        $this->assertSame(['د. علاء', 'ممرضة'], array_column($res->json('data'), 'name'), 'active only, in the set order');
        $this->assertSame('رئيس قسم الباطني', $res->json('data.0.role'));
        // The linked doctor comes shaped like /api/doctors rows.
        $this->assertSame(6, $res->json('data.0.doctor.id'));
        $this->assertSame('باطني', $res->json('data.0.doctor.category.name'));
        $this->assertSame('الخليل', $res->json('data.0.doctor.city.name'));
        $this->assertStringEndsWith('/storage/doctors/a.jpg', $res->json('data.0.doctor.image'));
        $this->assertFalse($res->json('data.0.doctor.booking_enabled'));
        $this->assertNull($res->json('data.1.doctor'));

        $this->getJson('/api/staff/lab/3')->assertOk()->assertExactJson(['data' => []]);
        $this->getJson('/api/staff/lab/99')->assertNotFound();
        $this->getJson('/api/staff/job/1')->assertNotFound();

        $this->getJson('/api/admin/staff?filter[target_id]=4', $this->admin())->assertOk()->assertJsonPath('total', 3);

        // The whole-table list feeds the dashboard's team cells without a lookup per row.
        DB::enableQueryLog();
        $all = $this->getJson('/api/admin/staff/all', $this->admin())->assertOk()->json();
        $this->assertCount(4, $all);
        $this->assertArrayNotHasKey('place_name', $all[0]);
        $this->assertLessThan(8, count(DB::getQueryLog()), 'query count must not grow with the rows');
    }

    public function test_examples_fill_only_places_without_a_team()
    {
        DB::table('staff_members')->insert(['type' => 'hospital', 'target_id' => 4, 'name' => 'حقيقي', 'role' => 'مدير']);

        // doctor 6 (3) + hospital 5 (4) + lab 3 (3); hospital 4 already has a team.
        $this->assertSame(10, StaffExamples::fill());
        $this->assertSame(1, DB::table('staff_members')->where('target_id', 4)->where('type', 'hospital')->count());
        $this->assertSame(0, StaffExamples::fill(), 'running it again adds nothing');

        $team = $this->getJson('/api/staff/doctor/6')->assertOk()->json('data');
        $this->assertCount(3, $team);
        $this->assertSame('ممرضة العيادة', $team[0]['role']);
    }
}
