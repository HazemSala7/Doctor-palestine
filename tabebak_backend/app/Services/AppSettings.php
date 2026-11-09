<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/** Key/value texts and links the app shows, edited on the dashboard's settings page. */
class AppSettings
{
    /** key => validation rules. Only these keys can be read or written. */
    public const RULES = [
        'tagline' => ['nullable', 'string', 'max:120'],
        'about_us' => ['nullable', 'string', 'max:20000'],
        'privacy_policy' => ['nullable', 'string', 'max:50000'],
        'support_whatsapp' => ['nullable', 'string', 'max:30'],
        'support_phone' => ['nullable', 'string', 'max:30'],
        'support_email' => ['nullable', 'email', 'max:120'],
        'facebook_url' => ['nullable', 'url', 'max:300'],
        'instagram_url' => ['nullable', 'url', 'max:300'],
        'tiktok_url' => ['nullable', 'url', 'max:300'],
        'website_url' => ['nullable', 'url', 'max:300'],
        // '1': patients' reviews are published at once instead of waiting for approval.
        'reviews_auto_approve' => ['nullable', 'in:0,1'],
    ];

    /** Every key, '' when unset. */
    public static function all(): array
    {
        $stored = Schema::hasTable('app_settings')
            ? DB::table('app_settings')->whereIn('key', array_keys(self::RULES))->pluck('value', 'key')->all()
            : [];

        $out = [];
        foreach (array_keys(self::RULES) as $key) {
            $out[$key] = (string) ($stored[$key] ?? '');
        }

        return $out;
    }

    public static function save(array $values): void
    {
        $now = now();
        foreach (array_intersect_key($values, self::RULES) as $key => $value) {
            DB::table('app_settings')->updateOrInsert(
                ['key' => $key],
                ['value' => $value ?? '', 'updated_at' => $now, 'created_at' => $now]
            );
        }
    }
}
