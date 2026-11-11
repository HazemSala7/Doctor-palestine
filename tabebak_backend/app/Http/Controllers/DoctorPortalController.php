<?php

namespace App\Http\Controllers;

use App\Http\Middleware\DoctorToken;
use App\Services\Booking;
use App\Services\Reviews;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/** The signed-in doctor's side of the app: bookings, schedule and patients' reviews. */
class DoctorPortalController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'phone.required' => 'رقم الهاتف مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
        ]);

        $account = DB::table('doctor_accounts')->where('phone', Booking::accountPhone($request->input('phone')))->first();
        if (! $account || ! Hash::check($request->input('password'), $account->password)) {
            return $this->json(['message' => 'رقم الهاتف أو كلمة المرور غير صحيحة'], 401);
        }
        if (! $account->active) {
            return $this->json(['message' => 'هذا الحساب موقوف، تواصل مع إدارة طبيبك'], 403);
        }

        DB::table('doctor_accounts')->where('id', $account->id)->update(['last_login_at' => now()]);

        return $this->json(['token' => DoctorToken::issue($account)] + $this->profile($account));
    }

    public function me(Request $request)
    {
        return $this->json($this->profile($this->account($request)));
    }

    /** GET doctor/appointments?scope=upcoming|today|past|all */
    public function appointments(Request $request)
    {
        $account = $this->account($request);
        $today = Booking::today();
        $scope = (string) $request->query('scope', 'upcoming');

        $q = DB::table('doctor_appointments')->where('doctor_id', $account->doctor_id);
        switch ($scope) {
            case 'today':
                $q->where('date', $today)->orderBy('time');
                break;
            case 'past':
                $q->where('date', '<', $today)->orderByDesc('date')->orderByDesc('time');
                break;
            case 'all':
                $q->orderByDesc('date')->orderByDesc('time');
                break;
            default:
                $q->where('date', '>=', $today)->orderBy('date')->orderBy('time');
        }

        $summary = DB::table('doctor_appointments')
            ->where('doctor_id', $account->doctor_id)
            ->where('date', '>=', $today)
            ->selectRaw('SUM(date = ? AND status IN (?, ?)) as today', [$today, 'pending', 'confirmed'])
            ->selectRaw("SUM(status = 'pending') as pending")
            ->selectRaw("SUM(status = 'confirmed') as confirmed")
            ->first();

        return $this->json([
            'today' => $today,
            'summary' => [
                'today' => (int) ($summary->today ?? 0),
                'pending' => (int) ($summary->pending ?? 0),
                'confirmed' => (int) ($summary->confirmed ?? 0),
            ],
            'data' => $q->limit(300)->get()->map(fn ($a) => Booking::presentAppointment($a))->values(),
        ]);
    }

    /** POST doctor/appointments/{id}/status {status} */
    public function updateStatus(Request $request, int $id)
    {
        $account = $this->account($request);
        $request->validate(['status' => ['required', 'in:confirmed,cancelled,completed,pending']]);

        $appointment = DB::table('doctor_appointments')
            ->where('id', $id)
            ->where('doctor_id', $account->doctor_id)
            ->first();
        abort_unless($appointment, 404, 'الموعد غير موجود');

        $status = $request->input('status');
        // Bringing a cancelled booking back must not double-book its slot.
        if (in_array($status, Booking::ACTIVE, true) && ! in_array($appointment->status, Booking::ACTIVE, true)) {
            $clash = DB::table('doctor_appointments')
                ->where('doctor_id', $account->doctor_id)
                ->where('date', $appointment->date)
                ->where('time', $appointment->time)
                ->where('id', '!=', $id)
                ->whereIn('status', Booking::ACTIVE)
                ->exists();
            if ($clash) {
                return $this->json(['message' => 'هذا الوقت محجوز لمريض آخر'], 409);
            }
        }

        DB::table('doctor_appointments')->where('id', $id)->update(['status' => $status, 'updated_at' => now()]);

        return $this->json(Booking::presentAppointment(DB::table('doctor_appointments')->where('id', $id)->first()));
    }

    /** PUT doctor/schedule */
    public function updateSchedule(Request $request)
    {
        $account = $this->account($request);
        $data = $request->validate([
            'booking_enabled' => ['required', 'boolean'],
            'work_days' => ['required', 'array', 'min:1'],
            'work_days.*' => ['integer', 'between:0,6'],
            'work_start' => ['required', 'date_format:H:i'],
            'work_end' => ['required', 'date_format:H:i', 'after:work_start'],
            'slot_minutes' => ['required', 'integer', 'in:' . implode(',', Booking::SLOT_LENGTHS)],
        ], [
            'work_days.required' => 'اختر يوم عمل واحداً على الأقل',
            'work_days.min' => 'اختر يوم عمل واحداً على الأقل',
            'work_end.after' => 'وقت نهاية الدوام يجب أن يكون بعد بدايته',
            'slot_minutes.in' => 'مدة الموعد غير مدعومة',
        ]);

        $days = array_values(array_unique(array_map('intval', $data['work_days'])));
        sort($days);
        DB::table('doctor_accounts')->where('id', $account->id)->update([
            'booking_enabled' => $data['booking_enabled'] ? 1 : 0,
            'work_days' => implode(',', $days),
            'work_start' => $data['work_start'],
            'work_end' => $data['work_end'],
            'slot_minutes' => (int) $data['slot_minutes'],
            'updated_at' => now(),
        ]);

        return $this->json($this->profile(DB::table('doctor_accounts')->where('id', $account->id)->first()));
    }

    /** GET doctor/reviews?page= : the doctor's published reviews. */
    public function reviews(Request $request)
    {
        return $this->json(Reviews::page('doctor', (int) $this->account($request)->doctor_id, (int) $request->query('page', 1)));
    }

    /** POST doctor/reviews/{id}/reply {reply} : an empty reply removes it. */
    public function reply(Request $request, int $id)
    {
        $account = $this->account($request);
        $data = $request->validate(['reply' => ['nullable', 'string', 'max:1000']], [
            'reply.max' => 'الرد طويل جداً (1000 حرف كحد أقصى)',
        ]);
        $review = DB::table('reviews')
            ->where('id', $id)
            ->where('type', 'doctor')
            ->where('target_id', $account->doctor_id)
            ->where('status', 'approved')
            ->first();
        if (! $review) {
            return $this->json(['message' => 'التقييم غير موجود'], 404);
        }

        $reply = trim((string) ($data['reply'] ?? '')) ?: null;
        DB::table('reviews')->where('id', $id)->update([
            'reply' => $reply,
            'replied_at' => $reply ? now() : null,
            'updated_at' => now(),
        ]);

        return $this->json(Reviews::present(DB::table('reviews')->where('id', $id)->first()));
    }

    /** POST doctor/password {current_password, password} */
    public function changePassword(Request $request)
    {
        $account = $this->account($request);
        $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:6', 'max:100'],
        ], [
            'password.min' => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
        ]);
        if (! Hash::check($request->input('current_password'), $account->password)) {
            return $this->json([
                'message' => 'كلمة المرور الحالية غير صحيحة',
                'errors' => ['current_password' => ['كلمة المرور الحالية غير صحيحة']],
            ], 422);
        }

        DB::table('doctor_accounts')->where('id', $account->id)->update([
            'password' => Hash::make($request->input('password')),
            'updated_at' => now(),
        ]);
        // The old token stops working with the old password; hand out a new one.
        $fresh = DB::table('doctor_accounts')->where('id', $account->id)->first();

        return $this->json(['token' => DoctorToken::issue($fresh)]);
    }

    /**
     * POST doctor/account/delete {password}
     * The doctor deletes their own account: sign-in, number, password and
     * schedule go, and every token stops working. Bookings still to come are
     * cancelled so patients see it; the doctor's page in the directory and
     * past appointments stay.
     */
    public function deleteAccount(Request $request)
    {
        $account = $this->account($request);
        $request->validate(['password' => ['required', 'string']], [
            'password.required' => 'اكتب كلمة المرور لتأكيد الحذف',
        ]);
        if (! Hash::check($request->input('password'), $account->password)) {
            return $this->json([
                'message' => 'كلمة المرور غير صحيحة',
                'errors' => ['password' => ['كلمة المرور غير صحيحة']],
            ], 422);
        }

        $cancelled = DB::transaction(function () use ($account) {
            $cancelled = DB::table('doctor_appointments')
                ->where('doctor_id', $account->doctor_id)
                ->where('date', '>=', Booking::today())
                ->whereIn('status', ['pending', 'confirmed'])
                ->update(['status' => 'cancelled', 'updated_at' => now()]);
            DB::table('doctor_accounts')->where('id', $account->id)->delete();

            return $cancelled;
        });

        return $this->json(['deleted' => true, 'cancelled_appointments' => $cancelled]);
    }

    private function account(Request $request)
    {
        return $request->attributes->get('doctor_account');
    }

    private function profile($account): array
    {
        $doctor = DB::table('doctors')->where('id', $account->doctor_id)->first();
        $category = $doctor && $doctor->category_id
            ? DB::table('doctor_categories')->where('id', $doctor->category_id)->value('name')
            : null;
        $image = $doctor->image ?? null;
        if ($image && ! preg_match('#^https?:#', $image)) {
            $image = url('/') . '/storage/' . ltrim($image, '/');
        }

        return [
            'account' => Booking::presentAccount($account),
            'doctor' => $doctor ? [
                'id' => (int) $doctor->id,
                'name' => $doctor->name,
                'image' => $image,
                'specialty' => $category,
            ] : null,
        ];
    }

    private function json($data, int $status = 200)
    {
        return response()->json($data, $status, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
