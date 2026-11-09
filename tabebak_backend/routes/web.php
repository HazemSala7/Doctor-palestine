<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
Route::get('/admin/advertisement-targets/{type}', function ($type) {
    $modelMap = [
        'hospital' => \App\Hospital::class,
        'pharmacy' => \App\Pharmacy::class,
        'doctor' => \App\Doctor::class,
        'lab' => \App\Laboratory::class,
        'radiology' => \App\RadiologyCenter::class,
        'beauty_center' => \App\BeautyCenter::class,
        'warehouse' => \App\MedicalWarehouse::class,
        'nutrition' => \App\NutritionCenter::class,
        'optic' => \App\Optic::class,
        'treatment_center' => \App\MedicalTreatmentCenter::class,
        'job' => \App\Job::class,
        'city' => \App\City::class,
    ];

    $model = $modelMap[$type] ?? null;

    if (!$model) {
        return response()->json([]);
    }

    return $model::select('id', 'name')->get();
});

Route::get('/', function () {
    return view('welcome');
});

// The host can't create the public/storage symlink, so uploaded images
// (Voyager and the dashboard) are served from the public disk here.
Route::get('storage/{path}', function (string $path) {
    $disk = \Illuminate\Support\Facades\Storage::disk('public');
    abort_if(str_contains($path, '..'), 404);
    abort_unless($disk->exists($path), 404);

    return $disk->response($path, null, ['Cache-Control' => 'public, max-age=2592000']);
})->where('path', '.*');


Route::group(['prefix' => 'admin'], function () {
    Voyager::routes();
});

Route::get('/linkstorage', function () {
    Artisan::call('storage:link');
});



