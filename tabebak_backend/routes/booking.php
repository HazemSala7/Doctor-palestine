<?php

use App\Http\Controllers\BookingController;
use App\Http\Controllers\DoctorPageController;
use App\Http\Controllers\DoctorPortalController;
use App\Http\Middleware\DoctorToken;
use Illuminate\Support\Facades\Route;

/*
| Appointment booking. Included from routes/api.php.
|   Patients (no account): /api/doctors/{id}/booking, /api/appointments/{code}
|   Doctors (DoctorToken): /api/doctor/...
*/

Route::get('doctors/{id}/booking', [BookingController::class, 'availability'])->whereNumber('id');
Route::post('doctors/{id}/appointments', [BookingController::class, 'store'])->whereNumber('id')->middleware('throttle:6,1');
Route::get('appointments/{code}', [BookingController::class, 'show']);
Route::post('appointments/{code}/cancel', [BookingController::class, 'cancel'])->middleware('throttle:10,1');

Route::prefix('doctor')->group(function () {
    Route::post('login', [DoctorPortalController::class, 'login'])->middleware('throttle:10,1');

    Route::middleware(DoctorToken::class)->group(function () {
        Route::get('me', [DoctorPortalController::class, 'me']);
        Route::get('appointments', [DoctorPortalController::class, 'appointments']);
        Route::post('appointments/{id}/status', [DoctorPortalController::class, 'updateStatus'])->whereNumber('id');
        Route::match(['put', 'post'], 'schedule', [DoctorPortalController::class, 'updateSchedule']);
        Route::post('password', [DoctorPortalController::class, 'changePassword']);
        Route::get('reviews', [DoctorPortalController::class, 'reviews']);
        Route::post('reviews/{id}/reply', [DoctorPortalController::class, 'reply'])->whereNumber('id');

        // The doctor's own page and team.
        Route::get('page', [DoctorPageController::class, 'show']);
        Route::post('page', [DoctorPageController::class, 'update']);
        Route::get('staff', [DoctorPageController::class, 'staff']);
        Route::post('staff', [DoctorPageController::class, 'storeStaff']);
        Route::post('staff/reorder', [DoctorPageController::class, 'reorderStaff']);
        Route::post('staff/{id}', [DoctorPageController::class, 'updateStaff'])->whereNumber('id');
        Route::post('staff/{id}/delete', [DoctorPageController::class, 'destroyStaff'])->whereNumber('id');
        Route::get('reels', [DoctorPageController::class, 'reels']);
        Route::post('reels', [DoctorPageController::class, 'storeReel']);
        Route::post('reels/{id}', [DoctorPageController::class, 'updateReel'])->whereNumber('id');
        Route::post('reels/{id}/delete', [DoctorPageController::class, 'destroyReel'])->whereNumber('id');
    });
});
