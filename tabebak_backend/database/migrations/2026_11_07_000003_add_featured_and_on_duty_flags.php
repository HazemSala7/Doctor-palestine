<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Dashboard switches: which doctors the home screen features,
 * and which pharmacies are on duty right now.
 */
return new class extends Migration
{
    public function up()
    {
        if (! Schema::hasColumn('doctors', 'featured')) {
            Schema::table('doctors', function (Blueprint $table) {
                $table->boolean('featured')->default(false);
            });
        }
        if (! Schema::hasColumn('pharmacies', 'on_duty')) {
            Schema::table('pharmacies', function (Blueprint $table) {
                $table->boolean('on_duty')->default(false);
            });
        }
    }

    public function down()
    {
        if (Schema::hasColumn('doctors', 'featured')) {
            Schema::table('doctors', fn (Blueprint $table) => $table->dropColumn('featured'));
        }
        if (Schema::hasColumn('pharmacies', 'on_duty')) {
            Schema::table('pharmacies', fn (Blueprint $table) => $table->dropColumn('on_duty'));
        }
    }
};
