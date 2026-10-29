<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\DoctorCategory;
use App\City;

class FilterController extends Controller
{
    public function getFilterData(Request $request)
    {
        $categories = DoctorCategory::select('id', 'name')->get();
        $cities = City::select('id', 'name')->get();

        return response()->json([
            'categories' => $categories,
            'cities' => $cities,
        ], 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
    }
}
