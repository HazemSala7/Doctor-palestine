<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\RadiologyCenter;

class RadiologyCenterController extends Controller
{
public function index(Request $request)
{
    $query = RadiologyCenter::with('city');

    // Optional filter by city
    if ($request->has('city_id')) {
        $query->where('city_id', $request->city_id);
    }

    $pharmacies = $query->paginate(10);

    foreach ($pharmacies as $pharmacy) {
        $pharmacy->coordinates = $pharmacy->getCoordinates();
    }

    return response()->json($pharmacies, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}

}
