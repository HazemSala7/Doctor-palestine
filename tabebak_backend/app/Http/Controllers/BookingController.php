<?php

namespace App\Http\Controllers;

use App\Services\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Patients book without an account. Each booking returns a secret `code`
 * the app keeps, which is how the patient later checks or cancels it.
 */
class BookingController extends Controller
{
    /** GET doctors/{id}/booking?date=Y-m-d : schedule and the day's slots. */
    public function availability(Request $request, int $id)
    {
        $account = Booking::bookableAccount($id);
        if (! $account) {
            return $this->json(['enabled' => false]);
        }

        $date = (string) $request->query('date', Booking::today());
        if ($error = $this->dateError($date)) {
            return $this->json(['message' => $error], 422);
        }

        return $this->json([
            'enabled' => true,
            'work_days' => Booking::workDays($account),
            'slot_minutes' => (int) $account->slot_minutes,
            'today' => Booking::today(),
            'days_ahead' => Booking::DAYS_AHEAD,
            'date' => $date,
            'slots' => Booking::availability($account, $date),
        ]);
    }

    /** POST doctors/{id}/appointments */
    public function store(Request $request, int $id)
    {
        $data = $request->validate([
            'patient_name' => ['required', 'string', 'min:2', 'max:100'],
            'patient_phone' => ['required', 'string', 'max:20'],
            'date' => ['required', 'date_format:Y-m-d'],
            'time' => ['required', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:500'],
        ], [
            'patient_name.required' => 'الاسم مطلوب',
            'patient_name.min' => 'الاسم قصير جداً',
            'patient_phone.required' => 'رقم الهاتف مطلوب',
            'date.*' => 'التاريخ غير صحيح',
            'time.*' => 'الوقت غير صحيح',
        ]);

        $phone = Booking::normalizePhone($data['patient_phone']);
        if (strlen($phone) < 9 || strlen($phone) > 15) {
            return $this->fieldError('patient_phone', 'رقم الهاتف غير صحيح');
        }
        if ($error = Booking::dateError($data['date'])) {
            return $this->fieldError('date', $error);
        }

        // The account row is locked so two patients can't take the same slot.
        return DB::transaction(function () use ($id, $data, $phone) {
            $account = DB::table('doctor_accounts')
                ->where('doctor_id', $id)
                ->where('active', 1)
                ->where('booking_enabled', 1)
                ->lockForUpdate()
                ->first();
            if (! $account) {
                return $this->json(['message' => 'الحجز عبر التطبيق غير متاح لهذا الطبيب'], 404);
            }

            $slot = collect(Booking::availability($account, $data['date']))->firstWhere('time', $data['time']);
            if (! $slot) {
                return $this->fieldError('time', 'هذا الوقت خارج ساعات عمل الطبيب');
            }
            if (! $slot['available']) {
                return $this->fieldError('time', 'هذا الموعد محجوز، اختر وقتاً آخر', 409);
            }

            $now = now();
            $code = Str::random(40);
            $appointmentId = DB::table('doctor_appointments')->insertGetId([
                'doctor_id' => $id,
                'code' => $code,
                'patient_name' => trim($data['patient_name']),
                'patient_phone' => $phone,
                'date' => $data['date'],
                'time' => $data['time'],
                'status' => 'pending',
                'notes' => $data['notes'] ?? null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $appointment = DB::table('doctor_appointments')->where('id', $appointmentId)->first();

            return $this->json(Booking::presentAppointment($appointment) + ['code' => $code], 201);
        });
    }

    /** GET appointments/{code} */
    public function show(string $code)
    {
        $appointment = $this->byCode($code);
        $doctor = DB::table('doctors')->where('id', $appointment->doctor_id)->first(['id', 'name', 'image', 'mobile', 'address']);

        return $this->json(Booking::presentAppointment($appointment) + ['doctor' => $doctor]);
    }

    /** POST appointments/{code}/cancel */
    public function cancel(string $code)
    {
        $appointment = $this->byCode($code);
        if (! in_array($appointment->status, Booking::ACTIVE, true)) {
            return $this->json(['message' => 'لا يمكن إلغاء هذا الموعد'], 422);
        }
        DB::table('doctor_appointments')->where('id', $appointment->id)->update(['status' => 'cancelled', 'updated_at' => now()]);

        return $this->show($code);
    }

    private function byCode(string $code)
    {
        $appointment = DB::table('doctor_appointments')->where('code', $code)->first();
        abort_unless($appointment, 404, 'الموعد غير موجود');

        return $appointment;
    }

    private function dateError(string $date): ?string
    {
        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) ? Booking::dateError($date) : 'التاريخ غير صحيح';
    }

    private function fieldError(string $field, string $message, int $status = 422)
    {
        return $this->json(['message' => $message, 'errors' => [$field => [$message]]], $status);
    }

    private function json($data, int $status = 200)
    {
        return response()->json($data, $status, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
