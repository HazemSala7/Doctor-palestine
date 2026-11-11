<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The live `advertisements.type` was a fixed list from the old system, so the
 * dashboard's targets ("doctor", "lab", ...) failed with "Data truncated".
 * As text it takes every target the dashboard offers; existing values stay.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql' || ! Schema::hasColumn('advertisements', 'type')) {
            return;
        }
        $type = DB::table('information_schema.COLUMNS')
            ->where('TABLE_SCHEMA', DB::getDatabaseName())
            ->where('TABLE_NAME', 'advertisements')
            ->where('COLUMN_NAME', 'type')
            ->value('COLUMN_TYPE');
        if (! str_starts_with(strtolower((string) $type), 'enum')) {
            return;
        }
        DB::statement('ALTER TABLE `advertisements` MODIFY `type` VARCHAR(32) NULL');
    }

    public function down(): void
    {
        // A fixed list again would truncate the targets it now holds.
    }
};
