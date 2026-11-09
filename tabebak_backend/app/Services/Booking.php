<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Schedule and slot rules shared by the patient booking API, the doctor API
 * and the dashboard. Times are local Palestine time; the app runs in UTC.
 */
class Booking
{
    public const TZ = 'Asia/Hebron';
    public const DAYS_AHEAD = 30;
    /** Statuses that hold a slot. */
    public const ACTIVE = ['pending', 'confirmed'];
    public const STATUSES = ['pending', 'confirmed', 'cancelled', 'completed'];
    public const SLOT_LENGTHS = [10, 15, 20, 30, 45, 60, 90, 120];

    public static function now(): Carbon
    {
        return Carbon::now(self::TZ);
    }

    public static function today(): string
    {
        return self::now()->toDateString();
    }

    /** 0 = Saturday ... 6 = Friday. */
    public static function dayIndex(Carbon $date): int
    {
        return ($date->dayOfWeek + 1) % 7;
    }

    /** A number people can really be reached on: 7-15 digits, with the usual separators. */
    public const PHONE_FORMAT = '/^(?=(?:\D*\d){7,15}\D*$)\+?[0-9\s()-]{7,25}$/';

    /** Digits only, so "059-123 4567" and "0591234567" log in the same. */
    public static function normalizePhone(?string $phone): string
    {
        return preg_replace('/\D+/', '', (string) $phone);
    }

    /** A doctor's login: "+972 59…", "00970 59…" and "059…" are the same number. */
    public static function accountPhone(?string $phone): string
    {
        $digits = self::normalizePhone($phone);

        return preg_match('/^(?:00)?97[02]0?(\d{8,9})$/', $digits, $m) ? '0' . $m[1] : $digits;
    }

    public static function workDays($account): array
    {
        return array_values(array_unique(array_map('intval', array_filter(
            explode(',', (string) $account->work_days),
            fn ($d) => $d !== '' && is_numeric($d)
        ))));
    }

    /** The account that takes bookings for a doctor, or null. */
    public static function bookableAccount(int $doctorId)
    {
        return DB::table('doctor_accounts')
            ->where('doctor_id', $doctorId)
            ->where('active', 1)
            ->where('booking_enabled', 1)
            ->first();
    }

    /** Ids among $doctorIds that can be booked from the app. */
    public static function enabledDoctorIds($doctorIds): array
    {
        // Lets the public API keep working before the booking tables exist.
        if (! Schema::hasTable('doctor_accounts')) {
            return [];
        }

        return DB::table('doctor_accounts')
            ->whereIn('doctor_id', collect($doctorIds)->all())
            ->where('active', 1)
            ->where('booking_enabled', 1)
            ->pluck('doctor_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /** Every slot start ("09:30") on $date, ignoring bookings. Empty on days off. */
    public static function slotsFor($account, string $date): array
    {
        $day = Carbon::createFromFormat('Y-m-d', $date, self::TZ)->startOfDay();
        if (! in_array(self::dayIndex($day), self::workDays($account), true)) {
            return [];
        }

        $step = max(5, (int) $account->slot_minutes);
        [$sh, $sm] = array_map('intval', explode(':', $account->work_start));
        [$eh, $em] = array_map('intval', explode(':', $account->work_end));
        $end = $eh * 60 + $em;

        $slots = [];
        for ($t = $sh * 60 + $sm; $t + $step <= $end; $t += $step) {
            $slots[] = sprintf('%02d:%02d', intdiv($t, 60), $t % 60);
        }

        return $slots;
    }

    /** Slot starts already held on $date. */
    public static function takenTimes(int $doctorId, string $date): array
    {
        return DB::table('doctor_appointments')
            ->where('doctor_id', $doctorId)
            ->where('date', $date)
            ->whereIn('status', self::ACTIVE)
            ->pluck('time')
            ->all();
    }

    /** [['time' => '09:00', 'available' => bool], ...] for the booking screen. */
    public static function availability($account, string $date): array
    {
        $taken = array_flip(self::takenTimes((int) $account->doctor_id, $date));
        $now = self::now();
        $isToday = $date === $now->toDateString();
        $nowTime = $now->format('H:i');

        return array_map(fn ($time) => [
            'time' => $time,
            'available' => ! isset($taken[$time]) && ! ($isToday && $time <= $nowTime),
        ], self::slotsFor($account, $date));
    }

    /** Null when $date is a day patients may book; otherwise the reason. */
    public static function dateError(string $date): ?string
    {
        // "!" zeroes the time, so the 30-day limit compares whole days.
        $d = Carbon::createFromFormat('!Y-m-d', $date, self::TZ);
        if (! $d || $d->toDateString() !== $date) {
            return 'التاريخ غير صحيح';
        }
        $today = self::now()->startOfDay();
        if ($d->lt($today)) {
            return 'لا يمكن الحجز في تاريخ مضى';
        }
        if ($d->gt($today->copy()->addDays(self::DAYS_AHEAD))) {
            return 'يمكن الحجز خلال ' . self::DAYS_AHEAD . ' يوماً فقط';
        }

        return null;
    }

    public static function presentAccount($account): array
    {
        return [
            'id' => (int) $account->id,
            'doctor_id' => (int) $account->doctor_id,
            'phone' => $account->phone,
            'active' => (bool) $account->active,
            'booking_enabled' => (bool) $account->booking_enabled,
            'work_days' => self::workDays($account),
            'work_start' => $account->work_start,
            'work_end' => $account->work_end,
            'slot_minutes' => (int) $account->slot_minutes,
        ];
    }

    public static function presentAppointment($a, bool $withPatient = true): array
    {
        $out = [
            'id' => (int) $a->id,
            'doctor_id' => (int) $a->doctor_id,
            'date' => $a->date,
            'time' => $a->time,
            'status' => $a->status,
            'created_at' => $a->created_at,
        ];
        if ($withPatient) {
            $out += [
                'patient_name' => $a->patient_name,
                'patient_phone' => $a->patient_phone,
                'notes' => $a->notes,
            ];
        }

        return $out;
    }
}
