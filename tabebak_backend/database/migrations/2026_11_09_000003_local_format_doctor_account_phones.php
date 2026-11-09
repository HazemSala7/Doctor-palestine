<?php

use App\Services\Booking;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Accounts saved as 97259… must keep working now that a login is matched as 059…. */
return new class extends Migration
{
    public function up()
    {
        if (! Schema::hasTable('doctor_accounts')) {
            return;
        }
        foreach (DB::table('doctor_accounts')->get(['id', 'phone']) as $account) {
            $local = Booking::accountPhone($account->phone);
            // A second account already on that number is left for the admin to sort out.
            if ($local !== $account->phone && ! DB::table('doctor_accounts')->where('phone', $local)->exists()) {
                DB::table('doctor_accounts')->where('id', $account->id)->update(['phone' => $local]);
            }
        }
    }

    public function down()
    {
        // The original format is not kept; 059… numbers still work.
    }
};
