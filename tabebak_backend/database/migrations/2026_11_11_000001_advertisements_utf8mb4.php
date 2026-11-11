<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The live `advertisements` table was created in a single-byte charset, so an
 * Arabic title failed with "Incorrect string value". Converting re-encodes the
 * existing rows; nothing is dropped.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasTable('advertisements')) {
            return;
        }
        $collation = DB::table('information_schema.TABLES')
            ->where('TABLE_SCHEMA', DB::getDatabaseName())
            ->where('TABLE_NAME', 'advertisements')
            ->value('TABLE_COLLATION');
        if (str_starts_with((string) $collation, 'utf8mb4')) {
            return;
        }
        DB::statement('ALTER TABLE `advertisements` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    }

    public function down(): void
    {
        // Going back would break the Arabic rows it now holds.
    }
};
