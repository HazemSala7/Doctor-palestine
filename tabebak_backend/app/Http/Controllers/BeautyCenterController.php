<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\BeautyCenter;

class BeautyCenterController extends Controller
{
public function index(Request $request)
{
    $query = BeautyCenter::with('city');

    // Filter by city if city_id is provided
    if ($request->has('city_id')) {
        $query->where('city_id', $request->city_id);
    }

    $hospitals = $query->paginate(10);

    foreach ($hospitals as $hospital) {
        $hospital->coordinates = $hospital->getCoordinates();
    }

    return response()->json($hospitals, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}

}
