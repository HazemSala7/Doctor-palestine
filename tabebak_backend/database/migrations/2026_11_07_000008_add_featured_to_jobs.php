<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Jobs chosen on the dashboard for the home screen's banner. */
return new class extends Migration
{
    public function up()
    {
        if (Schema::hasTable('jobs') && ! Schema::hasColumn('jobs', 'featured')) {
            Schema::table('jobs', function (Blueprint $table) {
                $table->boolean('featured')->default(false);
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('jobs') && Schema::hasColumn('jobs', 'featured')) {
            Schema::table('jobs', function (Blueprint $table) {
                $table->dropColumn('featured');
            });
        }
    }
};
