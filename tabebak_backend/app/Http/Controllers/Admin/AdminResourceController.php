<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\Booking;
use App\Services\Reviews;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * One controller serves CRUD for every table the dashboard manages.
 * It talks to the tables directly and stores data exactly the way
 * Voyager does, so the app's existing API keeps reading it unchanged.
 */
class AdminResourceController extends Controller
{
    /**
     * Dashboard section => table settings.
     * `spatial`: the `coordinates` column is a MySQL POINT (Voyager's Spatial trait).
     */
    public const RESOURCES = [
        'doctors' => ['table' => 'doctors', 'images' => ['image'], 'required' => ['name', 'category_id', 'city_id'], 'spatial' => true],
        'doctor-categories' => ['table' => 'doctor_categories', 'images' => ['image'], 'required' => ['name']],
        'cities' => ['table' => 'cities', 'images' => ['image'], 'required' => ['name']],
        'hospitals' => ['table' => 'hospitals', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'pharmacies' => ['table' => 'pharmacies', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'laboratories' => ['table' => 'laboratories', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'radiology_centers' => ['table' => 'radiology_centers', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'beauty_centers' => ['table' => 'beauty_centers', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'medical_warehouses' => ['table' => 'medical_warehouses', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'nutrition_centers' => ['table' => 'nutrition_centers', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'optics' => ['table' => 'optics', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'medical_treatment_centers' => ['table' => 'medical_treatment_centers', 'images' => ['logo_image', 'cover_image'], 'required' => ['name', 'city_id'], 'spatial' => true],
        'jobs' => ['table' => 'jobs', 'images' => [], 'required' => ['title', 'type', 'city_id']],
        'sliders' => ['table' => 'sliders', 'images' => ['image'], 'required' => ['image']],
        // `enums`: allowed values per column.
        'advertisements' => [
            'table' => 'advertisements', 'images' => ['image'], 'required' => ['title', 'image'],
            'enums' => ['placement' => ['banner', 'premium', 'vip']],
        ],
        // Booking. `password`: hashed on write, never returned, required only on create.
        // `hidden`: never returned. `unique`: one row per value. `phones`: stored as digits.
        // `token`: random secret generated on create. `recent`: false keeps rows off the dashboard feed.
        'doctor-accounts' => [
            'table' => 'doctor_accounts', 'images' => [], 'required' => ['doctor_id', 'phone'],
            'password' => 'password', 'hidden' => ['password'], 'unique' => ['doctor_id', 'phone'],
            'phones' => ['phone'], 'recent' => false,
        ],
        // `videos`: uploaded video files. `urls`: must be links. `one_of`: at least one must be set.
        'reels' => [
            'table' => 'reels', 'images' => ['thumbnail'], 'videos' => ['video'], 'urls' => ['video_url'],
            'one_of' => ['video', 'video_url'], 'required' => ['title'],
        ],
        'appointments' => [
            'table' => 'doctor_appointments', 'images' => [],
            'required' => ['doctor_id', 'patient_name', 'patient_phone', 'date', 'time', 'status'],
            'hidden' => ['code'], 'token' => 'code', 'phones' => ['patient_phone'], 'recent' => false,
        ],
        // `derived`: set by the server only. `type`/`target_id` name the place like ad targets.
        'reviews' => [
            'table' => 'reviews', 'images' => [],
            'required' => ['type', 'target_id', 'name', 'phone', 'rating', 'status'],
            'phones' => ['phone'], 'derived' => ['verified', 'appointment_id', 'replied_at'],
        ],
        // The team on a doctor's or centre's page; `doctor_id` links a doctor listed in the app.
        'staff' => [
            'table' => 'staff_members', 'images' => ['image'], 'required' => ['type', 'target_id', 'name', 'role'],
            'recent' => false,
        ],
    ];

    private const SEARCHABLE = ['name', 'title', 'address', 'mobile', 'location', 'description', 'phone', 'patient_name', 'patient_phone', 'role', 'comment'];
    private const SYSTEM = ['id', 'created_at', 'updated_at', 'deleted_at'];
    private const INTEGERS = ['city_id', 'category_id', 'target_id', 'experiance', 'doctor_id', 'slot_minutes', 'views', 'rating', 'sort_order'];
    /** Sections whose rows belong to a doctor or centre through `type` + `target_id`. */
    private const PLACE_ROWS = ['reviews', 'staff'];
    /** Kept up to date by the server on every place table (see App\Services\Reviews). */
    private const DERIVED = ['rating_avg', 'rating_count'];
    /** Social link columns => base URL for a bare "@handle" or page name. */
    private const SOCIAL = ['facebook_url' => 'https://www.facebook.com/', 'instagram_url' => 'https://www.instagram.com/'];
    private const VIDEO_TYPES = ['video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v'];
    private const VIDEO_MAX_KB = 100 * 1024;

    // ---------------------------------------------------------------- reads

    public function index(Request $request, string $resource)
    {
        [$cfg, $columns] = $this->resolve($resource);
        $query = $this->query($cfg, $columns);
        $table = $cfg['table'];

        if ($q = trim((string) $request->query('q', ''))) {
            $query->where(function ($w) use ($q, $columns, $table) {
                if (ctype_digit($q)) {
                    $w->orWhere("$table.id", (int) $q);
                }
                foreach (array_intersect(self::SEARCHABLE, $columns) as $col) {
                    $w->orWhere("$table.$col", 'like', '%' . $q . '%');
                }
            });
        }

        foreach ((array) $request->query('filter', []) as $col => $value) {
            if (in_array($col, $columns, true) && $value !== '' && $value !== null) {
                $query->where("$table.$col", $value);
            }
        }

        $sort = (string) $request->query('sort', '-id');
        $col = ltrim($sort, '-');
        $query->orderBy($table . '.' . (in_array($col, $columns, true) ? $col : 'id'), str_starts_with($sort, '-') ? 'desc' : 'asc');

        $perPage = max(1, min(100, (int) $request->query('per_page', 10)));
        $page = $query->paginate($perPage);

        return $this->json([
            'data' => array_map(fn ($row) => $this->present($cfg, $row), $page->items()),
            'total' => $page->total(),
            'current_page' => $page->currentPage(),
            'last_page' => $page->lastPage(),
        ]);
    }

    /** Whole small tables (cities, categories) for dropdowns. */
    public function all(string $resource)
    {
        [$cfg, $columns] = $this->resolve($resource);
        $rows = $this->query($cfg, $columns)->orderBy($cfg['table'] . '.id')->limit(2000)->get();

        return $this->json($rows->map(fn ($row) => $this->present($cfg, $row, false))->values());
    }

    public function show(string $resource, int $id)
    {
        [$cfg, $columns] = $this->resolve($resource);

        return $this->json($this->present($cfg, $this->find($cfg, $columns, $id)));
    }

    // --------------------------------------------------------------- writes

    public function store(Request $request, string $resource)
    {
        [$cfg, $columns] = $this->resolve($resource);
        $data = $this->validated($request, $resource, $cfg, $columns, null);
        if (! empty($cfg['token'])) {
            $data[$cfg['token']] = Str::random(40);
        }

        $now = now();
        foreach (['created_at', 'updated_at'] as $col) {
            if (in_array($col, $columns, true)) {
                $data[$col] = $now;
            }
        }
        $id = DB::table($cfg['table'])->insertGetId($data);
        $this->afterWrite($resource, [$data]);

        return $this->json($this->present($cfg, $this->find($cfg, $columns, $id)), 201);
    }

    public function update(Request $request, string $resource, int $id)
    {
        [$cfg, $columns] = $this->resolve($resource);
        $this->find($cfg, $columns, $id);

        $before = DB::table($cfg['table'])->where('id', $id)->first();
        $data = $this->validated($request, $resource, $cfg, $columns, $id);
        if (in_array('updated_at', $columns, true)) {
            $data['updated_at'] = now();
        }
        DB::table($cfg['table'])->where('id', $id)->update($data);
        $this->afterWrite($resource, [$before, DB::table($cfg['table'])->where('id', $id)->first()]);

        return $this->json($this->present($cfg, $this->find($cfg, $columns, $id)));
    }

    /**
     * Rows are removed for good, as Voyager does: the app's models don't
     * use SoftDeletes, so a soft-deleted row would still show in the app.
     */
    public function destroy(string $resource, int $id)
    {
        [$cfg] = $this->resolve($resource);
        $rows = DB::table($cfg['table'])->where('id', $id)->get()->all();
        DB::table($cfg['table'])->where('id', $id)->delete();
        $this->afterWrite($resource, $rows);
        $this->afterDelete($cfg, [$id]);

        return response()->noContent();
    }

    public function bulkDelete(Request $request, string $resource)
    {
        [$cfg] = $this->resolve($resource);
        $ids = array_values(array_filter(array_map('intval', (array) $request->input('ids', []))));
        abort_if(empty($ids), 422, 'لم يتم تحديد أي سجل');
        $rows = DB::table($cfg['table'])->whereIn('id', $ids)->get()->all();
        DB::table($cfg['table'])->whereIn('id', $ids)->delete();
        $this->afterWrite($resource, $rows);
        $this->afterDelete($cfg, $ids);

        return response()->noContent();
    }

    /** A deleted doctor or centre takes its team and reviews with it; a doctor also its login. */
    private function afterDelete(array $cfg, array $ids): void
    {
        $type = array_search($cfg['table'], Reviews::TYPES, true);
        if ($type === false) {
            return;
        }
        foreach (['reviews', 'staff_members'] as $table) {
            if (Schema::hasTable($table)) {
                DB::table($table)->where('type', $type)->whereIn('target_id', $ids)->delete();
            }
        }
        if ($type === 'doctor' && Schema::hasTable('doctor_accounts')) {
            DB::table('doctor_accounts')->whereIn('doctor_id', $ids)->delete();
        }
    }

    // ---------------------------------------------------------------- stats

    public function stats()
    {
        $counts = [];
        $recent = [];
        foreach (self::RESOURCES as $key => $cfg) {
            if (! Schema::hasTable($cfg['table'])) {
                $counts[$key] = 0;
                continue;
            }
            $columns = Schema::getColumnListing($cfg['table']);
            $counts[$key] = DB::table($cfg['table'])->count();
            if ($key !== 'sliders' && ($cfg['recent'] ?? true) && in_array('created_at', $columns, true)) {
                foreach ($this->query($cfg, $columns)->latest($cfg['table'] . '.created_at')->limit(8)->get() as $row) {
                    $recent[] = ['resource' => $key, 'row' => $this->present($cfg, $row)];
                }
            }
        }
        usort($recent, fn ($a, $b) => strcmp((string) ($b['row']['created_at'] ?? ''), (string) ($a['row']['created_at'] ?? '')));

        $tally = function (string $col) {
            if (! Schema::hasColumn('doctors', $col)) {
                return [];
            }

            return DB::table('doctors')
                ->whereNotNull($col)
                ->groupBy($col)
                ->select($col . ' as id', DB::raw('count(*) as count'))
                ->get()
                ->map(fn ($r) => ['id' => (int) $r->id, 'count' => (int) $r->count])
                ->values();
        };

        return $this->json([
            'counts' => $counts,
            'doctorsByCity' => $tally('city_id'),
            'doctorsByCategory' => $tally('category_id'),
            'recent' => array_slice($recent, 0, 8),
        ]);
    }

    /** Setup check: which configured tables exist and what columns they have. */
    public function health()
    {
        $out = [];
        foreach (self::RESOURCES as $key => $cfg) {
            $exists = Schema::hasTable($cfg['table']);
            $out[$key] = [
                'table' => $cfg['table'],
                'exists' => $exists,
                'columns' => $exists ? Schema::getColumnListing($cfg['table']) : [],
            ];
        }

        return $this->json($out);
    }

    // -------------------------------------------------------------- helpers

    private function json($data, int $status = 200)
    {
        return response()->json($data, $status, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }

    /** Rows written or deleted (old and new versions): reviews refresh their place's rating. */
    private function afterWrite(string $resource, array $rows): void
    {
        if ($resource !== 'reviews') {
            return;
        }
        $places = [];
        foreach ($rows as $row) {
            $row = (array) $row;
            if (! empty($row['type']) && ! empty($row['target_id'])) {
                $places[$row['type'] . ':' . $row['target_id']] = [$row['type'], (int) $row['target_id']];
            }
        }
        foreach ($places as [$type, $id]) {
            Reviews::refresh($type, $id);
        }
    }

    /** @return array{0: array, 1: string[]} */
    private function resolve(string $resource): array
    {
        $cfg = self::RESOURCES[$resource] ?? null;
        abort_unless($cfg, 404, 'قسم غير معروف');
        abort_unless(Schema::hasTable($cfg['table']), 500, "الجدول {$cfg['table']} غير موجود، عدّل RESOURCES في AdminResourceController");

        return [$cfg, Schema::getColumnListing($cfg['table'])];
    }

    /** Base query; POINT columns come back as WKT text. */
    private function query(array $cfg, array $columns)
    {
        $table = $cfg['table'];
        $q = DB::table($table)->select("$table.*");
        if (! empty($cfg['spatial']) && in_array('coordinates', $columns, true)) {
            $q->addSelect(DB::raw("ST_AsText(`$table`.`coordinates`) as coordinates"));
        }

        return $q;
    }

    private function find(array $cfg, array $columns, int $id)
    {
        $row = $this->query($cfg, $columns)->where($cfg['table'] . '.id', $id)->first();
        abort_unless($row, 404, 'السجل غير موجود');

        return $row;
    }

    /** Validates the request and returns only real, writable columns. `$id` is null when creating. */
    private function validated(Request $request, string $resource, array $cfg, array $columns, ?int $id): array
    {
        $creating = $id === null;
        $writable = array_values(array_diff($columns, self::SYSTEM, self::DERIVED, $cfg['derived'] ?? [], (array) ($cfg['token'] ?? [])));
        $passwordCol = $cfg['password'] ?? null;

        foreach ($cfg['phones'] ?? [] as $col) {
            if ($request->filled($col)) {
                $value = $request->input($col);
                $request->merge([$col => $resource === 'doctor-accounts' ? Booking::accountPhone($value) : Booking::normalizePhone($value)]);
            }
        }
        // "@tabebak" or "tabebak.ps" → full profile link; "facebook.com/x" → https://facebook.com/x.
        foreach (self::SOCIAL as $col => $base) {
            $v = trim((string) $request->input($col, ''));
            if ($v === '' || preg_match('#^https?://#i', $v)) {
                continue;
            }
            $request->merge([$col => preg_match('#^(www\.)?(facebook|fb|instagram)\.(com|me)/#i', $v)
                ? 'https://' . $v
                : $base . ltrim($v, '@/')]);
        }

        $rules = [];
        foreach ($writable as $col) {
            $required = in_array($col, $cfg['required'], true);
            if ($col === $passwordCol) {
                // Left empty on edit, the current password stays.
                $rules[$col] = [$creating ? 'required' : 'nullable', 'string', 'min:6'];
            } elseif (in_array($col, $cfg['images'], true)) {
                // On update an image is only required if it is being removed.
                $rules[$col] = [($required && ($creating || $request->boolean($col . '__remove'))) ? 'required' : 'nullable', 'image', 'max:5120'];
            } elseif (in_array($col, $cfg['videos'] ?? [], true)) {
                $rules[$col] = ['nullable', 'file', 'mimetypes:' . implode(',', self::VIDEO_TYPES), 'max:' . self::VIDEO_MAX_KB];
            } elseif (in_array($col, $cfg['urls'] ?? [], true) || isset(self::SOCIAL[$col])) {
                $rules[$col] = ['nullable', 'url', 'max:500'];
            } elseif ($col === 'coordinates') {
                $rules[$col] = ['nullable', 'json'];
            } else {
                $rules[$col] = [$required ? 'required' : 'nullable'];
                if (in_array($col, self::INTEGERS, true)) {
                    $rules[$col][] = 'integer';
                }
                if (in_array($col, $cfg['unique'] ?? [], true)) {
                    $rules[$col][] = Rule::unique($cfg['table'], $col)->ignore($id);
                }
            }
        }
        foreach ($cfg['enums'] ?? [] as $col => $allowed) {
            if (isset($rules[$col])) {
                $rules[$col][] = Rule::in($allowed);
            }
        }
        if ($resource === 'appointments') {
            $rules['status'][] = Rule::in(Booking::STATUSES);
            $rules['date'][] = 'date_format:Y-m-d';
            $rules['time'][] = 'date_format:H:i';
        }
        if (in_array($resource, self::PLACE_ROWS, true)) {
            $rules['type'][] = Rule::in(array_keys(Reviews::TYPES));
        }
        if ($resource === 'reviews') {
            $rules['status'][] = Rule::in(Reviews::STATUSES);
            $rules['rating'][] = 'between:1,5';
            $rules['phone'][] = Rule::unique('reviews', 'phone')->ignore($id)
                ->where('type', (string) $request->input('type'))
                ->where('target_id', (int) $request->input('target_id'));
        }

        // A bad number would give applicants a WhatsApp button that leads nowhere.
        if ($resource === 'jobs' && isset($rules['mobile'])) {
            $rules['mobile'][] = 'regex:' . Booking::PHONE_FORMAT;
        }

        $videoMessages = [];
        foreach ($cfg['videos'] ?? [] as $col) {
            $videoMessages["$col.max"] = 'حجم الفيديو يجب ألا يتجاوز ' . (self::VIDEO_MAX_KB / 1024) . ' ميجابايت';
            $videoMessages["$col.mimetypes"] = 'صيغة الفيديو غير مدعومة، استخدم MP4 أو MOV أو WebM';
            $videoMessages["$col.uploaded"] = 'فشل رفع الفيديو، جرّب ملفاً أصغر';
        }

        Validator::make($request->all(), $rules, $videoMessages + [
            'url' => 'الرابط غير صحيح، يجب أن يبدأ بـ https://',
            'unique' => 'هذه القيمة مستخدمة في حساب آخر',
            'min' => 'يجب ألا يقل عن :min أحرف',
            'in' => 'القيمة غير صحيحة',
            'between' => 'التقييم من 1 إلى 5',
            'date_format' => 'الصيغة غير صحيحة',
            'required' => 'هذا الحقل مطلوب',
            'image' => 'يجب أن يكون الملف صورة',
            'max' => 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت',
            'json' => 'صيغة الإحداثيات غير صحيحة',
            'integer' => 'القيمة غير صحيحة',
            'regex' => 'رقم الهاتف غير صحيح، مثال: 0591234567',
        ])->validate();

        $media = array_merge($cfg['images'], $cfg['videos'] ?? []);
        $data = [];
        foreach ($writable as $col) {
            if (in_array($col, $media, true)) {
                if ($request->hasFile($col)) {
                    $data[$col] = $this->upload($request->file($col), $resource);
                } elseif ($request->boolean($col . '__remove')) {
                    $data[$col] = null;
                }
                // Otherwise the stored file stays as it is.
                continue;
            }
            if (! $request->exists($col)) {
                continue;
            }
            $value = $request->input($col);
            if ($col === $passwordCol) {
                if ($value !== '' && $value !== null) {
                    $data[$col] = Hash::make($value);
                }
                continue;
            }
            if ($col === 'coordinates') {
                $data[$col] = $this->coordinates($value, ! empty($cfg['spatial']));
                continue;
            }
            $data[$col] = ($value === '' || $value === null) ? null : $value;
        }

        // A premium or VIP ad opens a doctor's or centre's page, so it needs one.
        if ($resource === 'advertisements' && in_array($data['placement'] ?? null, ['premium', 'vip'], true)
            && (in_array($data['type'] ?? null, [null, 'job', 'city'], true) || empty($data['target_id']))) {
            $message = 'الإعلان المميز يجب أن يفتح صفحة طبيب أو مركز: اختر النوع والسجل المستهدف';
            abort(response()->json(['message' => $message, 'errors' => ['type' => [$message]]], 422));
        }

        if (in_array($resource, self::PLACE_ROWS, true)) {
            $existing = $creating ? [] : (array) DB::table($cfg['table'])->where('id', $id)->first();
            $type = $data['type'] ?? $existing['type'] ?? null;
            $target = (int) ($data['target_id'] ?? $existing['target_id'] ?? 0);
            if (! Reviews::placeExists((string) $type, $target)) {
                $message = $resource === 'reviews' ? 'اختر الطبيب أو المركز الذي يخصه التقييم' : 'اختر الطبيب أو المركز الذي يعمل فيه';
                abort(response()->json(['message' => $message, 'errors' => ['target_id' => [$message]]], 422));
            }
        }
        if ($resource === 'staff' && ! empty($data['doctor_id']) && ! DB::table('doctors')->where('id', $data['doctor_id'])->exists()) {
            abort(response()->json(['message' => 'الطبيب غير موجود', 'errors' => ['doctor_id' => ['الطبيب غير موجود']]], 422));
        }
        if ($resource === 'reviews') {
            if (array_key_exists('reply', $data) && $data['reply'] !== ($existing['reply'] ?? null)) {
                $data['replied_at'] = $data['reply'] === null ? null : now();
            }
        }

        // e.g. a reel needs an uploaded video or a link, whichever.
        if ($oneOf = $cfg['one_of'] ?? null) {
            $existing = $creating ? [] : (array) DB::table($cfg['table'])->where('id', $id)->first();
            $present = fn ($c) => array_key_exists($c, $data) ? $data[$c] !== null : ! empty($existing[$c]);
            if (! collect($oneOf)->contains($present)) {
                $message = 'ارفع ملف فيديو أو ضع رابطاً له';
                abort(response()->json(['message' => $message, 'errors' => [$oneOf[0] => [$message]]], 422));
            }
        }

        return $data;
    }

    /** `[{"lat":..,"lng":..}]` from the dashboard → POINT(lng lat) like Voyager writes. */
    private function coordinates($json, bool $spatial)
    {
        $points = $json ? json_decode($json, true) : null;
        $point = is_array($points) ? ($points[0] ?? $points) : null;
        if (! is_array($point) || ! isset($point['lat'], $point['lng']) || $point['lat'] === '' || $point['lng'] === '') {
            return null;
        }
        $lat = (float) $point['lat'];
        $lng = (float) $point['lng'];
        if (abs($lat) > 90 || abs($lng) > 180) {
            abort(response()->json(['message' => 'الإحداثيات خارج النطاق', 'errors' => ['coordinates' => ['الإحداثيات خارج النطاق']]], 422));
        }

        return $spatial
            ? DB::raw("ST_GeomFromText('POINT({$lng} {$lat})')")
            : json_encode([['lat' => (string) $lat, 'lng' => (string) $lng]]);
    }

    /** Stores like Voyager: <section>/<MonthYear>/<random>.<ext> on the public disk, path kept relative. */
    private function upload($file, string $resource): string
    {
        $dir = $resource . '/' . now()->format('FY');
        $name = Str::random(20) . '.' . strtolower($file->getClientOriginalExtension() ?: 'jpg');

        return $file->storeAs($dir, $name, config('voyager.storage.disk', 'public'));
    }

    /** Row for JSON: image URLs built like the app's models, coordinates as [{lat, lng}]. */
    private function present(array $cfg, $row, bool $withPlace = true): array
    {
        $row = array_diff_key((array) $row, array_flip($cfg['hidden'] ?? []));
        // Skipped for whole-table lists: it costs queries for every row.
        if ($withPlace && in_array($cfg['table'], ['reviews', 'staff_members'], true)) {
            $row['place_name'] = Reviews::placeName((string) $row['type'], (int) $row['target_id']);
        }
        foreach (array_merge($cfg['images'], $cfg['videos'] ?? []) as $col) {
            $path = $row[$col] ?? null;
            if ($path && ! preg_match('#^(https?:|data:)#', $path)) {
                $row[$col] = url('/') . '/storage/' . ltrim($path, '/');
            }
        }
        $c = $row['coordinates'] ?? null;
        if (is_string($c) && preg_match('/^POINT\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s*\)$/i', $c, $m)) {
            $row['coordinates'] = [['lat' => $m[2], 'lng' => $m[1]]];
        } elseif (is_string($c)) {
            $decoded = json_decode($c, true);
            $row['coordinates'] = is_array($decoded) ? $decoded : null;
        }

        return $row;
    }
}
