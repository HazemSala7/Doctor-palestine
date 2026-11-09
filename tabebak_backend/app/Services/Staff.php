<?php

namespace App\Services;

use App\Doctor;
use Illuminate\Support\Facades\DB;

/** The team listed on a doctor's or centre's page. Places use the same keys as reviews. */
class Staff
{
    /** Active members, in the dashboard's order, each with its linked doctor if any. */
    public static function forPlace(string $type, int $id): array
    {
        $members = DB::table('staff_members')
            ->where('type', $type)
            ->where('target_id', $id)
            ->where('active', 1)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        $doctors = self::doctors($members->pluck('doctor_id')->filter()->unique()->values()->all());

        return $members->map(fn ($m) => [
            'id' => (int) $m->id,
            'name' => $m->name,
            'role' => $m->role,
            'image' => $m->image ? self::url($m->image) : null,
            'bio' => $m->bio,
            'doctor' => $m->doctor_id ? ($doctors[(int) $m->doctor_id] ?? null) : null,
        ])->values()->all();
    }

    /** Shaped exactly like /api/doctors rows, so the app opens the doctor's page from it. */
    private static function doctors(array $ids): array
    {
        if (! $ids) {
            return [];
        }
        $bookable = Booking::enabledDoctorIds($ids);
        $out = [];
        foreach (Doctor::with(['city', 'category'])->whereIn('id', $ids)->get() as $doctor) {
            $doctor->coordinates = $doctor->getCoordinates();
            $doctor->booking_enabled = in_array((int) $doctor->id, $bookable, true);
            $out[(int) $doctor->id] = $doctor->toArray();
        }

        return $out;
    }

    public static function url(string $path): string
    {
        return preg_match('#^https?:#', $path) ? $path : url('/') . '/storage/' . ltrim($path, '/');
    }
}
