<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * `placement`: banner  = the home screen carousel (as before);
 *              premium = also a full-screen window when the app opens and
 *                        pinned, marked "sponsored", at the top of its list.
 * `description`: the short text shown in the premium window.
 */
return new class extends Migration
{
    public function up()
    {
        if (! Schema::hasTable('advertisements') || Schema::hasColumn('advertisements', 'placement')) {
            return;
        }
        Schema::table('advertisements', function (Blueprint $table) {
            $table->string('placement', 16)->default('banner');
            $table->text('description')->nullable();
        });
    }

    public function down()
    {
        if (Schema::hasColumn('advertisements', 'placement')) {
            Schema::table('advertisements', fn (Blueprint $table) => $table->dropColumn(['placement', 'description']));
        }
    }
};
