<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Like the advertisements table, the live `jobs` table was single-byte, so an
 * Arabic job title or description failed. Converting keeps the existing rows.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasTable('jobs')) {
            return;
        }
        $collation = DB::table('information_schema.TABLES')
            ->where('TABLE_SCHEMA', DB::getDatabaseName())
            ->where('TABLE_NAME', 'jobs')
            ->value('TABLE_COLLATION');
        if (str_starts_with((string) $collation, 'utf8mb4')) {
            return;
        }
        DB::statement('ALTER TABLE `jobs` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    }

    public function down(): void
    {
        // Going back would break the Arabic rows it now holds.
    }
};
