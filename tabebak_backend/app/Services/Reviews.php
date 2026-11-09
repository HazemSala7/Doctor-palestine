<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Ratings of doctors and centres. Only approved reviews count and show in the app. */
class Reviews
{
    /** Review `type` => the place's table (same keys as advertisement targets). */
    public const TYPES = [
        'doctor' => 'doctors',
        'hospital' => 'hospitals',
        'pharmacy' => 'pharmacies',
        'lab' => 'laboratories',
        'radiology' => 'radiology_centers',
        'beauty_center' => 'beauty_centers',
        'warehouse' => 'medical_warehouses',
        'nutrition' => 'nutrition_centers',
        'optic' => 'optics',
        'treatment_center' => 'medical_treatment_centers',
    ];

    public const STATUSES = ['pending', 'approved', 'rejected'];

    /** Set on the dashboard's settings page; off by default, so new reviews wait for approval. */
    public static function autoApprove(): bool
    {
        return (AppSettings::all()['reviews_auto_approve'] ?? '') === '1';
    }

    public static function placeExists(string $type, int $id): bool
    {
        $table = self::TYPES[$type] ?? null;

        return $table && Schema::hasTable($table) && DB::table($table)->where('id', $id)->exists();
    }

    public static function placeName(string $type, int $id): ?string
    {
        $table = self::TYPES[$type] ?? null;

        return $table && Schema::hasTable($table) ? DB::table($table)->where('id', $id)->value('name') : null;
    }

    private static function approved(string $type, int $id)
    {
        return DB::table('reviews')->where('type', $type)->where('target_id', $id)->where('status', 'approved');
    }

    /** Average, count and how many reviews gave each star. */
    public static function summary(string $type, int $id): array
    {
        $byStars = self::approved($type, $id)
            ->groupBy('rating')
            ->select('rating', DB::raw('count(*) as n'))
            ->pluck('n', 'rating');
        $count = (int) $byStars->sum();
        $total = $byStars->reduce(fn ($sum, $n, $stars) => $sum + $n * $stars, 0);

        $breakdown = [];
        foreach ([5, 4, 3, 2, 1] as $stars) {
            $breakdown[(string) $stars] = (int) ($byStars[$stars] ?? 0);
        }

        return [
            'average' => $count ? round($total / $count, 1) : null,
            'count' => $count,
            'breakdown' => $breakdown,
        ];
    }

    /** Stores the place's approved average and count on its own row. */
    public static function refresh(?string $type, ?int $id): void
    {
        $table = self::TYPES[$type] ?? null;
        if (! $table || ! $id || ! Schema::hasTable($table) || ! Schema::hasColumn($table, 'rating_avg')) {
            return;
        }
        $stats = self::approved($type, $id)->selectRaw('count(*) as n, avg(rating) as avg')->first();
        DB::table($table)->where('id', $id)->update([
            'rating_avg' => $stats->n ? round((float) $stats->avg, 2) : null,
            'rating_count' => (int) $stats->n,
        ]);
    }

    /** The public shape: the phone never leaves the server. */
    public static function present($r): array
    {
        return [
            'id' => (int) $r->id,
            'name' => $r->name,
            'rating' => (int) $r->rating,
            'comment' => $r->comment,
            'verified' => (bool) $r->verified,
            'reply' => $r->reply,
            'replied_at' => $r->replied_at,
            'created_at' => $r->created_at,
        ];
    }

    /** A page of approved reviews, newest first, with the summary. */
    public static function page(string $type, int $id, int $page, int $perPage = 10): array
    {
        $paginator = self::approved($type, $id)->orderByDesc('created_at')->orderByDesc('id')->paginate($perPage, ['*'], 'page', max(1, $page));

        return [
            'summary' => self::summary($type, $id),
            'data' => array_map([self::class, 'present'], $paginator->items()),
            'current_page' => $paginator->currentPage(),
            'last_page' => $paginator->lastPage(),
            'total' => $paginator->total(),
        ];
    }
}
