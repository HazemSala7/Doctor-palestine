<?php

namespace App\Http\Controllers;

use App\Services\Reviews;
use App\Services\Staff;

class StaffController extends Controller
{
    /** GET staff/{type}/{id} */
    public function index(string $type, int $id)
    {
        if (! Reviews::placeExists($type, $id)) {
            return response()->json(['message' => 'غير موجود'], 404);
        }

        return response()->json(['data' => Staff::forPlace($type, $id)], 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
