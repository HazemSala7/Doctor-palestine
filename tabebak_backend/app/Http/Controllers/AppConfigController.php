<?php

namespace App\Http\Controllers;

use App\Services\AppSettings;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Everything the app loads once at start-up: dashboard settings,
 * section counts and the advertisements running today.
 */
class AppConfigController extends Controller
{
    /** Sections counted for the app, keyed like their API paths. */
    private const SECTIONS = [
        'doctors', 'hospitals', 'pharmacies', 'laboratories', 'radiology_centers', 'beauty_centers',
        'medical_warehouses', 'nutrition_centers', 'optics', 'medical_treatment_centers', 'cities', 'jobs',
    ];

    /** Advertisement `type` => model of the record it opens. */
    private const AD_TARGETS = [
        'doctor' => \App\Doctor::class,
        'hospital' => \App\Hospital::class,
        'pharmacy' => \App\Pharmacy::class,
        'lab' => \App\Laboratory::class,
        'radiology' => \App\RadiologyCenter::class,
        'beauty_center' => \App\BeautyCenter::class,
        'warehouse' => \App\MedicalWarehouse::class,
        'nutrition' => \App\NutritionCenter::class,
        'optic' => \App\Optic::class,
        'treatment_center' => \App\MedicalTreatmentCenter::class,
        'job' => \App\Job::class,
        'city' => \App\City::class,
    ];

    public function show()
    {
        $counts = [];
        foreach (self::SECTIONS as $table) {
            $counts[$table] = Schema::hasTable($table) ? DB::table($table)->count() : 0;
        }

        return response()->json([
            'settings' => AppSettings::all(),
            'counts' => $counts,
            'doctors_by_city' => $this->tally('city_id'),
            'doctors_by_category' => $this->tally('category_id'),
            'advertisements' => $this->advertisements(),
        ], 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }

    /** {"<id>": count} of doctors per value of $column. */
    private function tally(string $column): object
    {
        return (object) DB::table('doctors')
            ->whereNotNull($column)
            ->groupBy($column)
            ->select($column, DB::raw('count(*) as n'))
            ->pluck('n', $column)
            ->map(fn ($n) => (int) $n)
            ->all();
    }

    private function advertisements(): array
    {
        if (! Schema::hasTable('advertisements')) {
            return [];
        }
        $today = now('Asia/Hebron')->toDateString();
        $premium = Schema::hasColumn('advertisements', 'placement');
        $query = DB::table('advertisements')
            ->where('active', 1)
            ->where(fn ($q) => $q->whereNull('start_date')->orWhere('start_date', '<=', $today))
            ->where(fn ($q) => $q->whereNull('end_date')->orWhere('end_date', '>=', $today));
        // VIP, then premium, then the rest, so the limit never drops a paid ad.
        if ($premium) {
            $query->orderByRaw("CASE placement WHEN 'vip' THEN 0 WHEN 'premium' THEN 1 ELSE 2 END");
        }
        $ads = $query->orderByDesc('id')->limit(10)->get();

        return $ads->map(fn ($ad) => [
            'id' => (int) $ad->id,
            'title' => $ad->title,
            'placement' => $premium ? ($ad->placement ?: 'banner') : 'banner',
            'description' => $premium ? $ad->description : null,
            'image' => $ad->image && ! preg_match('#^https?:#', $ad->image)
                ? url('/') . '/storage/' . ltrim($ad->image, '/')
                : $ad->image,
            'type' => $ad->type,
            'target' => $this->target($ad->type, (int) $ad->target_id),
        ])->values()->all();
    }

    /** The record an ad opens, shaped like that section's list API rows. */
    private function target(?string $type, int $id)
    {
        $model = self::AD_TARGETS[$type] ?? null;
        if (! $model || ! $id) {
            return null;
        }
        $relations = array_filter(['city', 'category'], fn ($r) => method_exists($model, $r));
        $row = $model::with($relations)->find($id);
        if (! $row) {
            return null;
        }
        if (method_exists($row, 'getCoordinates')) {
            $row->coordinates = $row->getCoordinates();
        }
        // Lets the app offer "book" on the ad, as the doctors list does.
        if ($type === 'doctor') {
            $row->booking_enabled = in_array((int) $row->id, \App\Services\Booking::enabledDoctorIds([$row->id]), true);
        }

        return $row;
    }
}
