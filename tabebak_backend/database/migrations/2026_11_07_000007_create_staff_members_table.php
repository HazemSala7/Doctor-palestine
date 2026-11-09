<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The team shown on a doctor's or centre's page (nurses, technicians, the
 * centre's doctors...). `type` + `target_id` name the place like reviews do.
 * `doctor_id` links a member who is also a doctor listed in the app.
 */
return new class extends Migration
{
    public function up()
    {
        if (Schema::hasTable('staff_members')) {
            return;
        }
        Schema::create('staff_members', function (Blueprint $table) {
            $table->id();
            $table->string('type', 30);
            $table->unsignedBigInteger('target_id');
            $table->string('name', 80);
            $table->string('role', 80);
            $table->string('image')->nullable();
            $table->text('bio')->nullable();
            $table->unsignedBigInteger('doctor_id')->nullable();
            $table->integer('sort_order')->default(0);
            $table->boolean('active')->default(true);
            $table->timestamps();
            $table->index(['type', 'target_id', 'active']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('staff_members');
    }
};
