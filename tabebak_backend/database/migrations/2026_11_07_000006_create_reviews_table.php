<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Patients' ratings and comments on doctors and centres.
 * `type` + `target_id` name the place the way advertisements do ("doctor", "lab", ...).
 * Each place table keeps its approved average and count, so the list APIs return them as is.
 */
return new class extends Migration
{
    public const TABLES = [
        'doctors', 'hospitals', 'pharmacies', 'laboratories', 'radiology_centers', 'beauty_centers',
        'medical_warehouses', 'nutrition_centers', 'optics', 'medical_treatment_centers',
    ];

    public function up()
    {
        if (! Schema::hasTable('reviews')) {
            Schema::create('reviews', function (Blueprint $table) {
                $table->id();
                $table->string('type', 30);
                $table->unsignedBigInteger('target_id');
                $table->string('name', 60);
                // Never shown in the app: one review per phone per place.
                $table->string('phone', 20);
                $table->unsignedTinyInteger('rating');
                $table->text('comment')->nullable();
                // pending | approved | rejected
                $table->string('status', 20)->default('pending');
                // Written after a completed appointment booked in the app.
                $table->boolean('verified')->default(false);
                $table->unsignedBigInteger('appointment_id')->nullable();
                $table->text('reply')->nullable();
                $table->timestamp('replied_at')->nullable();
                $table->timestamps();

                $table->unique(['type', 'target_id', 'phone']);
                $table->index(['type', 'target_id', 'status']);
            });
        }

        foreach (self::TABLES as $name) {
            if (! Schema::hasTable($name) || Schema::hasColumn($name, 'rating_avg')) {
                continue;
            }
            Schema::table($name, function (Blueprint $table) {
                $table->decimal('rating_avg', 3, 2)->nullable();
                $table->unsignedInteger('rating_count')->default(0);
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('reviews');
        foreach (self::TABLES as $name) {
            if (Schema::hasTable($name) && Schema::hasColumn($name, 'rating_avg')) {
                Schema::table($name, fn (Blueprint $table) => $table->dropColumn(['rating_avg', 'rating_count']));
            }
        }
    }
};
