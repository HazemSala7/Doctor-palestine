<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Laboratory;

class LaboratoryController extends Controller
{
public function index(Request $request)
{
    $query = Laboratory::with('city');

    // Optional filter by city
    if ($request->has('city_id')) {
        $query->where('city_id', $request->city_id);
    }

    $laboratories = $query->paginate(10);

    foreach ($laboratories as $lab) {
        $lab->coordinates = $lab->getCoordinates();
    }

    return response()->json($laboratories, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}

}
