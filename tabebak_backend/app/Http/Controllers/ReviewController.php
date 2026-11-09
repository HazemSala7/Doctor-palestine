<?php

namespace App\Http\Controllers;

use App\Services\Booking;
use App\Services\Reviews;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Patients rate doctors and centres without an account. The phone number
 * (never shown) keeps it to one review per person per place; writing again
 * replaces the earlier review.
 */
class ReviewController extends Controller
{
    /** GET reviews/{type}/{id}?page= */
    public function index(Request $request, string $type, int $id)
    {
        if (! Reviews::placeExists($type, $id)) {
            return $this->json(['message' => 'غير موجود'], 404);
        }

        return $this->json(Reviews::page($type, $id, (int) $request->query('page', 1)));
    }

    /** POST reviews/{type}/{id} */
    public function store(Request $request, string $type, int $id)
    {
        if (! Reviews::placeExists($type, $id)) {
            return $this->json(['message' => 'غير موجود'], 404);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:60'],
            'phone' => ['required', 'string', 'max:20'],
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
            'appointment_code' => ['nullable', 'string', 'max:40'],
        ], [
            'name.required' => 'الاسم مطلوب',
            'name.min' => 'الاسم قصير جداً',
            'name.max' => 'الاسم طويل جداً',
            'phone.required' => 'رقم الهاتف مطلوب',
            'rating.*' => 'اختر من نجمة إلى خمس نجوم',
            'comment.max' => 'التعليق طويل جداً (1000 حرف كحد أقصى)',
        ]);

        $phone = Booking::normalizePhone($data['phone']);
        if (strlen($phone) < 9 || strlen($phone) > 15) {
            return $this->fieldError('phone', 'رقم الهاتف غير صحيح');
        }

        // A review written from a completed booking in the app is marked verified.
        $appointment = null;
        if (! empty($data['appointment_code'])) {
            $appointment = DB::table('doctor_appointments')->where('code', $data['appointment_code'])->first();
            if (! $appointment || $type !== 'doctor' || (int) $appointment->doctor_id !== $id) {
                return $this->fieldError('appointment_code', 'الموعد غير موجود');
            }
            if ($appointment->status !== 'completed') {
                return $this->fieldError('appointment_code', 'يمكنك تقييم الزيارة بعد أن يؤكد الطبيب إتمامها');
            }
        }

        $status = Reviews::autoApprove() ? 'approved' : 'pending';
        $key = ['type' => $type, 'target_id' => $id, 'phone' => $phone];
        $existing = DB::table('reviews')->where($key)->first();
        $now = now();
        $row = [
            'name' => trim($data['name']),
            'rating' => (int) $data['rating'],
            'comment' => trim((string) ($data['comment'] ?? '')) ?: null,
            'status' => $status,
            'verified' => $appointment || ($existing->verified ?? false),
            'appointment_id' => $appointment->id ?? ($existing->appointment_id ?? null),
            // A reply answered the old text; it no longer fits an edited review.
            'reply' => null,
            'replied_at' => null,
            'updated_at' => $now,
        ];

        if ($existing) {
            // An edited review is listed as new.
            DB::table('reviews')->where('id', $existing->id)->update($row + ['created_at' => $now]);
            $reviewId = $existing->id;
        } else {
            $reviewId = DB::table('reviews')->insertGetId($key + $row + ['created_at' => $now]);
        }
        Reviews::refresh($type, $id);

        return $this->json([
            'status' => $status,
            'updated' => (bool) $existing,
            'message' => $status === 'approved'
                ? 'شكراً لك! تم نشر تقييمك'
                : 'شكراً لك! سيظهر تقييمك بعد مراجعته',
            'review' => Reviews::present(DB::table('reviews')->where('id', $reviewId)->first()),
        ], $existing ? 200 : 201);
    }

    private function fieldError(string $field, string $message)
    {
        return $this->json(['message' => $message, 'errors' => [$field => [$message]]], 422);
    }

    private function json($data, int $status = 200)
    {
        return response()->json($data, $status, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
