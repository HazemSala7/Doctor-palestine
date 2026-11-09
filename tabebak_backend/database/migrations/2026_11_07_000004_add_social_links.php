<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Facebook and Instagram links for every doctor and centre, shown on its page in the app. */
return new class extends Migration
{
    public const TABLES = [
        'doctors', 'hospitals', 'pharmacies', 'laboratories', 'radiology_centers', 'beauty_centers',
        'medical_warehouses', 'nutrition_centers', 'optics', 'medical_treatment_centers',
    ];

    public function up()
    {
        foreach (self::TABLES as $name) {
            if (! Schema::hasTable($name) || Schema::hasColumn($name, 'facebook_url')) {
                continue;
            }
            Schema::table($name, function (Blueprint $table) {
                $table->string('facebook_url', 300)->nullable();
                $table->string('instagram_url', 300)->nullable();
            });
        }
    }

    public function down()
    {
        foreach (self::TABLES as $name) {
            if (Schema::hasTable($name) && Schema::hasColumn($name, 'facebook_url')) {
                Schema::table($name, fn (Blueprint $table) => $table->dropColumn(['facebook_url', 'instagram_url']));
            }
        }
    }
};
