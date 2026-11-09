<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\AppSettings;
use Illuminate\Http\Request;

/** The dashboard's "App settings" page. */
class AdminSettingsController extends Controller
{
    public function show()
    {
        return response()->json(AppSettings::all(), 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }

    public function update(Request $request)
    {
        $values = $request->validate(AppSettings::RULES, [
            'url' => 'الرابط غير صحيح، يجب أن يبدأ بـ https://',
            'email' => 'البريد الإلكتروني غير صحيح',
            'max' => 'النص أطول من المسموح',
        ]);
        AppSettings::save($values);

        return $this->show();
    }
}
