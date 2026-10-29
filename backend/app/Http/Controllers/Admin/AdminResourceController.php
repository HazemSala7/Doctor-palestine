<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

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
        'advertisements' => ['table' => 'advertisements', 'images' => ['image'], 'required' => ['title', 'image']],
    ];

    private const SEARCHABLE = ['name', 'title', 'address', 'mobile', 'location', 'description'];
    private const SYSTEM = ['id', 'created_at', 'updated_at', 'deleted_at'];
    private const INTEGERS = ['city_id', 'category_id', 'target_id', 'experiance'];

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

        return $this->json($rows->map(fn ($row) => $this->present($cfg, $row))->values());
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
        $data = $this->validated($request, $resource, $cfg, $columns, true);

        $now = now();
        foreach (['created_at', 'updated_at'] as $col) {
            if (in_array($col, $columns, true)) {
                $data[$col] = $now;
            }
        }
        $id = DB::table($cfg['table'])->insertGetId($data);

        return $this->json($this->present($cfg, $this->find($cfg, $columns, $id)), 201);
    }

    public function update(Request $request, string $resource, int $id)
    {
        [$cfg, $columns] = $this->resolve($resource);
        $this->find($cfg, $columns, $id);

        $data = $this->validated($request, $resource, $cfg, $columns, false);
        if (in_array('updated_at', $columns, true)) {
            $data['updated_at'] = now();
        }
        DB::table($cfg['table'])->where('id', $id)->update($data);

        return $this->json($this->present($cfg, $this->find($cfg, $columns, $id)));
    }

    /**
     * Rows are removed for good, as Voyager does: the app's models don't
     * use SoftDeletes, so a soft-deleted row would still show in the app.
     */
    public function destroy(string $resource, int $id)
    {
        [$cfg] = $this->resolve($resource);
        DB::table($cfg['table'])->where('id', $id)->delete();

        return response()->noContent();
    }

    public function bulkDelete(Request $request, string $resource)
    {
        [$cfg] = $this->resolve($resource);
        $ids = array_values(array_filter(array_map('intval', (array) $request->input('ids', []))));
        abort_if(empty($ids), 422, 'لم يتم تحديد أي سجل');
        DB::table($cfg['table'])->whereIn('id', $ids)->delete();

        return response()->noContent();
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
            if ($key !== 'sliders' && in_array('created_at', $columns, true)) {
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

    /** Validates the request and returns only real, writable columns. */
    private function validated(Request $request, string $resource, array $cfg, array $columns, bool $creating): array
    {
        $writable = array_values(array_diff($columns, self::SYSTEM));
        $rules = [];
        foreach ($writable as $col) {
            $required = in_array($col, $cfg['required'], true);
            if (in_array($col, $cfg['images'], true)) {
                // On update an image is only required if it is being removed.
                $rules[$col] = [($required && ($creating || $request->boolean($col . '__remove'))) ? 'required' : 'nullable', 'image', 'max:5120'];
            } elseif ($col === 'coordinates') {
                $rules[$col] = ['nullable', 'json'];
            } else {
                $rules[$col] = [$required ? 'required' : 'nullable'];
                if (in_array($col, self::INTEGERS, true)) {
                    $rules[$col][] = 'integer';
                }
            }
        }

        Validator::make($request->all(), $rules, [
            'required' => 'هذا الحقل مطلوب',
            'image' => 'يجب أن يكون الملف صورة',
            'max' => 'حجم الصورة يجب ألا يتجاوز 5 ميجابايت',
            'json' => 'صيغة الإحداثيات غير صحيحة',
            'integer' => 'القيمة غير صحيحة',
        ])->validate();

        $data = [];
        foreach ($writable as $col) {
            if (in_array($col, $cfg['images'], true)) {
                if ($request->hasFile($col)) {
                    $data[$col] = $this->upload($request->file($col), $resource);
                } elseif ($request->boolean($col . '__remove')) {
                    $data[$col] = null;
                }
                // Otherwise the stored image stays as it is.
                continue;
            }
            if (! $request->exists($col)) {
                continue;
            }
            $value = $request->input($col);
            if ($col === 'coordinates') {
                $data[$col] = $this->coordinates($value, ! empty($cfg['spatial']));
                continue;
            }
            $data[$col] = ($value === '' || $value === null) ? null : $value;
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
    private function present(array $cfg, $row): array
    {
        $row = (array) $row;
        foreach ($cfg['images'] as $col) {
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
