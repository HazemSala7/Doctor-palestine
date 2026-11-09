<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('doctor_appointments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('doctor_id');
            // Secret handed to the patient's phone so it can follow or cancel the booking.
            $table->string('code', 40)->unique();
            $table->string('patient_name', 100);
            $table->string('patient_phone', 20);
            $table->date('date');
            $table->string('time', 5);
            // pending | confirmed | cancelled | completed
            $table->string('status', 16)->default('pending');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['doctor_id', 'date']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('doctor_appointments');
    }
};
