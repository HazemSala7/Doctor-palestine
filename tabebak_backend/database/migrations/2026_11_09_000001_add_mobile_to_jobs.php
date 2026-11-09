<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** The number applicants reach by WhatsApp or a call from the job's page in the app. */
return new class extends Migration
{
    public function up()
    {
        if (Schema::hasTable('jobs') && ! Schema::hasColumn('jobs', 'mobile')) {
            Schema::table('jobs', function (Blueprint $table) {
                $table->string('mobile', 30)->nullable();
            });
        }
    }

    public function down()
    {
        if (Schema::hasTable('jobs') && Schema::hasColumn('jobs', 'mobile')) {
            Schema::table('jobs', function (Blueprint $table) {
                $table->dropColumn('mobile');
            });
        }
    }
};
