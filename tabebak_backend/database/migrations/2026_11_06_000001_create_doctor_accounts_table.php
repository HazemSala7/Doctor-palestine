<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A doctor's login and booking schedule. Kept apart from `doctors` because
 * the public API returns every column of that table.
 */
return new class extends Migration
{
    public function up()
    {
        Schema::create('doctor_accounts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('doctor_id')->unique();
            $table->string('phone', 20)->unique();
            $table->string('password');
            $table->boolean('active')->default(true);
            $table->boolean('booking_enabled')->default(true);
            // 0 = Saturday ... 6 = Friday, the same numbering the app uses.
            $table->string('work_days', 20)->default('0,1,2,3,4,5');
            $table->string('work_start', 5)->default('09:00');
            $table->string('work_end', 5)->default('17:00');
            $table->unsignedSmallInteger('slot_minutes')->default(30);
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('doctor_accounts');
    }
};
