<?php

namespace App\Http\Controllers;

use App\Services\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReelController extends Controller
{
    /** GET reels?page= : active reels, newest first, with their doctor. */
    public function index(Request $request)
    {
        $page = DB::table('reels')
            ->where('active', 1)
            ->where(fn ($q) => $q->whereNotNull('video')->orWhereNotNull('video_url'))
            ->orderByDesc('id')
            ->paginate(10);

        $doctorIds = collect($page->items())->pluck('doctor_id')->filter()->unique()->values();
        $doctors = DB::table('doctors')
            ->leftJoin('doctor_categories', 'doctor_categories.id', '=', 'doctors.category_id')
            ->leftJoin('cities', 'cities.id', '=', 'doctors.city_id')
            ->whereIn('doctors.id', $doctorIds)
            ->get([
                'doctors.id', 'doctors.name', 'doctors.image', 'doctors.description', 'doctors.mobile', 'doctors.address',
                'doctors.category_id', 'doctor_categories.name as category_name', 'doctors.city_id', 'cities.name as city_name',
            ])
            ->keyBy('id');
        $bookable = Booking::enabledDoctorIds($doctorIds);

        $data = array_map(function ($reel) use ($doctors, $bookable) {
            $d = $reel->doctor_id ? $doctors->get($reel->doctor_id) : null;

            return [
                'id' => (int) $reel->id,
                'title' => $reel->title,
                'description' => $reel->description,
                'video' => $reel->video ? self::url($reel->video) : $reel->video_url,
                'thumbnail' => $reel->thumbnail ? self::url($reel->thumbnail) : null,
                'views' => (int) $reel->views,
                'created_at' => $reel->created_at,
                // Shaped like /api/doctors rows so the app can open the doctor's page.
                'doctor' => $d ? [
                    'id' => (int) $d->id,
                    'name' => $d->name,
                    'image' => $d->image ? self::url($d->image) : null,
                    'description' => $d->description,
                    'mobile' => $d->mobile,
                    'address' => $d->address,
                    'category' => $d->category_id ? ['id' => (int) $d->category_id, 'name' => $d->category_name] : null,
                    'city' => $d->city_id ? ['id' => (int) $d->city_id, 'name' => $d->city_name] : null,
                    'booking_enabled' => in_array((int) $d->id, $bookable, true),
                ] : null,
            ];
        }, $page->items());

        return response()->json([
            'data' => $data,
            'current_page' => $page->currentPage(),
            'last_page' => $page->lastPage(),
        ], 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }

    /** POST reels/{id}/view */
    public function view(int $id)
    {
        DB::table('reels')->where('id', $id)->increment('views');

        return response()->noContent();
    }

    private static function url(string $path): string
    {
        return preg_match('#^https?:#', $path) ? $path : url('/') . '/storage/' . ltrim($path, '/');
    }
}
