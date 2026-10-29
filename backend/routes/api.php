<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\SliderController;
use App\Http\Controllers\HospitalController;
use App\Http\Controllers\LaboratoryController;
use App\Http\Controllers\PharmacyController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\DoctorController;
use App\Http\Controllers\BeautyCenterController;
use App\Http\Controllers\OpticController;
use App\Http\Controllers\MedicalTreatmentCenterController;
use App\Http\Controllers\NutritionCenterController;
use App\Http\Controllers\MedicalWarehouseController;
use App\Http\Controllers\RadiologyCenterController;
use App\Http\Controllers\FilterController;
use App\Http\Controllers\JobController;
use App\Http\Controllers\DoctorCategoryController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Admin dashboard API (/api/admin/...).
require __DIR__ . '/admin.php';

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
// Index routes for all models
Route::get('sliders', [SliderController::class, 'index']);
Route::get('/filters', [FilterController::class, 'getFilterData']);
Route::get('cities', [CityController::class, 'index']);
Route::get('hospitals', [HospitalController::class, 'index']);
Route::get('optics', [OpticController::class, 'index']);
Route::get('beauty_centers', [BeautyCenterController::class, 'index']);
Route::get('jobs', [JobController::class, 'index']);
Route::get('nutrition_centers', [NutritionCenterController::class, 'index']);
Route::get('medical_warehouses', [MedicalWarehouseController::class, 'index']);
Route::get('medical_treatment_centers', [MedicalTreatmentCenterController::class, 'index']);
Route::get('laboratories', [LaboratoryController::class, 'index']);
Route::get('radiology_centers', [RadiologyCenterController::class, 'index']);
Route::get('pharmacies', [PharmacyController::class, 'index']);
Route::get('doctors', [DoctorController::class, 'index']);
Route::get('doctors/{id}', [DoctorController::class, 'show']);
Route::get('doctors_by_specialization/{category_id}', [DoctorController::class, 'getDoctorsSpecialization']);
Route::get('doctor-categories', [DoctorCategoryController::class, 'index']);
