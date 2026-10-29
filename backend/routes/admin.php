<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminResourceController as R;
use App\Http\Middleware\AdminToken;
use Illuminate\Support\Facades\Route;

/*
| Dashboard API. Include from routes/api.php:
|     require __DIR__ . '/admin.php';
| Every route ends up under /api/admin/...
*/

Route::prefix('admin')->group(function () {
    Route::post('login', [AdminAuthController::class, 'login'])->middleware('throttle:10,1');

    Route::middleware(AdminToken::class)->group(function () {
        Route::get('me', [AdminAuthController::class, 'me']);
        Route::get('stats', [R::class, 'stats']);
        Route::get('health', [R::class, 'health']);

        Route::get('{resource}', [R::class, 'index']);
        Route::get('{resource}/all', [R::class, 'all']);
        Route::post('{resource}', [R::class, 'store']);
        Route::post('{resource}/bulk-delete', [R::class, 'bulkDelete']);
        Route::get('{resource}/{id}', [R::class, 'show'])->whereNumber('id');
        // Multipart updates arrive as POST + _method=PUT.
        Route::match(['put', 'post'], '{resource}/{id}', [R::class, 'update'])->whereNumber('id');
        Route::delete('{resource}/{id}', [R::class, 'destroy'])->whereNumber('id');
    });
});
