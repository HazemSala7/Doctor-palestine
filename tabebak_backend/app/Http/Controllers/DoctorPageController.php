<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Admin\AdminResourceController;
use App\Services\Booking;
use App\Services\Staff;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * A signed-in doctor edits their own page and team from the app. Saving goes
 * through the dashboard's code, so both behave the same; each request is first
 * cut down to the fields a doctor may change and tied to their own record.
 */
class DoctorPageController extends Controller
{
    private const PAGE_FIELDS = [
        'name', 'category_id', 'city_id', 'mobile', 'address', 'description',
        'facebook_url', 'instagram_url', 'coordinates', 'image__remove',
    ];
    private const STAFF_FIELDS = ['name', 'role', 'bio', 'active', 'image__remove'];
    private const REEL_FIELDS = ['title', 'description', 'active', 'thumbnail__remove'];

    private const MESSAGES = [
        'name.required' => 'الاسم مطلوب',
        'name.max' => 'الاسم طويل جداً',
        'role.required' => 'الوظيفة مطلوبة',
        'role.max' => 'اسم الوظيفة طويل جداً',
        'category_id.required' => 'اختر التخصص',
        'category_id.exists' => 'اختر التخصص',
        'city_id.required' => 'اختر المدينة',
        'city_id.exists' => 'اختر المدينة',
        'mobile.regex' => 'رقم الهاتف غير صحيح، مثال: 0591234567',
        'address.max' => 'العنوان طويل جداً',
        'description.max' => 'النبذة طويلة جداً (5000 حرف كحد أقصى)',
        'bio.max' => 'النبذة طويلة جداً (1000 حرف كحد أقصى)',
        'ids.required' => 'الترتيب غير صحيح',
        'title.required' => 'عنوان الفيديو مطلوب',
        'title.max' => 'العنوان طويل جداً (150 حرف كحد أقصى)',
    ];

    /** GET doctor/page : the doctor's editable details, the choices for them, and the team. */
    public function show(Request $request)
    {
        $doctorId = $this->doctorId($request);

        return $this->json([
            'doctor' => $this->admin()->show('doctors', $doctorId)->getData(true),
            'categories' => DB::table('doctor_categories')->orderBy('name')->get(['id', 'name']),
            'cities' => DB::table('cities')->orderBy('name')->get(['id', 'name']),
            'staff' => $this->team($doctorId),
        ]);
    }

    /** POST doctor/page */
    public function update(Request $request)
    {
        $doctorId = $this->doctorId($request);
        $this->allowOnly($request, self::PAGE_FIELDS);
        $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'category_id' => ['required', 'integer', Rule::exists('doctor_categories', 'id')],
            'city_id' => ['required', 'integer', Rule::exists('cities', 'id')],
            'mobile' => ['nullable', 'string', 'regex:' . Booking::PHONE_FORMAT],
            'address' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
        ], self::MESSAGES);

        return $this->admin()->update($request, 'doctors', $doctorId);
    }

    /** GET doctor/staff : the whole team, hidden members included. */
    public function staff(Request $request)
    {
        return $this->json(['data' => $this->team($this->doctorId($request))]);
    }

    /** POST doctor/staff */
    public function storeStaff(Request $request)
    {
        $doctorId = $this->doctorId($request);
        $this->validateMember($request);
        $request->merge([
            'type' => 'doctor',
            'target_id' => $doctorId,
            'sort_order' => (int) DB::table('staff_members')->where('type', 'doctor')->where('target_id', $doctorId)->max('sort_order') + 1,
        ]);

        return $this->admin()->store($request, 'staff');
    }

    /** POST doctor/staff/{id} */
    public function updateStaff(Request $request, int $id)
    {
        $doctorId = $this->doctorId($request);
        $this->ownMember($doctorId, $id);
        $this->validateMember($request);
        $request->merge(['type' => 'doctor', 'target_id' => $doctorId]);

        return $this->admin()->update($request, 'staff', $id);
    }

    /** POST doctor/staff/{id}/delete */
    public function destroyStaff(Request $request, int $id)
    {
        $this->ownMember($this->doctorId($request), $id);

        return $this->admin()->destroy('staff', $id);
    }

    /** POST doctor/staff/reorder {ids: [...]} : first id is shown first. */
    public function reorderStaff(Request $request)
    {
        $doctorId = $this->doctorId($request);
        $data = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer']], self::MESSAGES);

        foreach (array_values($data['ids']) as $position => $id) {
            DB::table('staff_members')->where('id', $id)->where('type', 'doctor')->where('target_id', $doctorId)
                ->update(['sort_order' => $position + 1, 'updated_at' => now()]);
        }

        return $this->json(['data' => $this->team($doctorId)]);
    }

    /** GET doctor/reels : the doctor's reels, hidden ones included, newest first. */
    public function reels(Request $request)
    {
        return $this->json(['data' => $this->ownReels($this->doctorId($request))]);
    }

    /** POST doctor/reels */
    public function storeReel(Request $request)
    {
        $doctorId = $this->doctorId($request);
        $this->validateReel($request);
        $request->merge(['doctor_id' => $doctorId]);

        return $this->admin()->store($request, 'reels');
    }

    /** POST doctor/reels/{id} : a video left out keeps the current one. */
    public function updateReel(Request $request, int $id)
    {
        $this->ownReel($this->doctorId($request), $id);
        $this->validateReel($request);

        return $this->admin()->update($request, 'reels', $id);
    }

    /** POST doctor/reels/{id}/delete */
    public function destroyReel(Request $request, int $id)
    {
        $this->ownReel($this->doctorId($request), $id);

        return $this->admin()->destroy('reels', $id);
    }

    private function validateReel(Request $request): void
    {
        $this->allowOnly($request, self::REEL_FIELDS, ['video', 'thumbnail']);
        $request->validate([
            'title' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:1000'],
            'active' => ['nullable', 'in:0,1'],
        ], ['description.max' => 'الوصف طويل جداً (1000 حرف كحد أقصى)'] + self::MESSAGES);
    }

    private function ownReels(int $doctorId)
    {
        return DB::table('reels')
            ->where('doctor_id', $doctorId)
            ->orderByDesc('id')
            ->get()
            ->map(fn ($r) => [
                'id' => (int) $r->id,
                'title' => $r->title,
                'description' => $r->description,
                'video' => $r->video ? Staff::url($r->video) : $r->video_url,
                'thumbnail' => $r->thumbnail ? Staff::url($r->thumbnail) : null,
                'active' => (bool) $r->active,
                'views' => (int) $r->views,
            ])
            ->values();
    }

    private function ownReel(int $doctorId, int $id): void
    {
        abort_unless(
            DB::table('reels')->where('id', $id)->where('doctor_id', $doctorId)->exists(),
            404,
            'الفيديو غير موجود'
        );
    }

    private function validateMember(Request $request): void
    {
        $this->allowOnly($request, self::STAFF_FIELDS);
        $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'role' => ['required', 'string', 'max:80'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'active' => ['nullable', 'in:0,1'],
        ], self::MESSAGES);
    }

    /** Drops everything else, wherever it came from: body, query string or uploads. */
    private function allowOnly(Request $request, array $fields, array $uploads = ['image']): void
    {
        $request->replace($request->only($fields));
        $request->query->replace([]);
        $request->files->replace(array_intersect_key($request->files->all(), array_flip($uploads)));
    }

    private function team(int $doctorId)
    {
        return DB::table('staff_members')
            ->where('type', 'doctor')
            ->where('target_id', $doctorId)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(fn ($m) => [
                'id' => (int) $m->id,
                'name' => $m->name,
                'role' => $m->role,
                'bio' => $m->bio,
                'image' => $m->image ? Staff::url($m->image) : null,
                'active' => (bool) $m->active,
            ])
            ->values();
    }

    private function ownMember(int $doctorId, int $id): void
    {
        abort_unless(
            DB::table('staff_members')->where('id', $id)->where('type', 'doctor')->where('target_id', $doctorId)->exists(),
            404,
            'الموظف غير موجود'
        );
    }

    private function doctorId(Request $request): int
    {
        return (int) $request->attributes->get('doctor_account')->doctor_id;
    }

    private function admin(): AdminResourceController
    {
        return app(AdminResourceController::class);
    }

    private function json($data, int $status = 200)
    {
        return response()->json($data, $status, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
