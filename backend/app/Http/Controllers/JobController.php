<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Job;

class JobController extends Controller
{
public function index(Request $request)
{
    $query = Job::with('city');

    // Filter by city if city_id is provided
    if ($request->has('city_id')) {
        $query->where('city_id', $request->city_id);
    }

    $hospitals = $query->paginate(10);

    return response()->json($hospitals, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}

}
