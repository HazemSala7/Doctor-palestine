<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Short vertical videos shown in the app's Reels tab. */
return new class extends Migration
{
    public function up()
    {
        Schema::create('reels', function (Blueprint $table) {
            $table->id();
            $table->string('title', 150);
            $table->text('description')->nullable();
            // Either an uploaded file (path on the public disk) or an external link.
            $table->string('video')->nullable();
            $table->string('video_url', 500)->nullable();
            $table->string('thumbnail')->nullable();
            // Optional: the doctor the reel promotes, opened from the reel.
            $table->unsignedBigInteger('doctor_id')->nullable()->index();
            $table->boolean('active')->default(true);
            $table->unsignedInteger('views')->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('reels');
    }
};
