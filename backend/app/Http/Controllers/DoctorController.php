<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Doctor;

class DoctorController extends Controller
{
public function index(Request $request)
{
    $query = Doctor::with(['city', 'category']);

    if ($request->has('city_id')) {
        $query->where('city_id', $request->city_id);
    }

    if ($request->has('category_id')) {
        $query->where('category_id', $request->category_id);
    }

    if ($request->has('key')) {
        $query->where('name', 'like', '%' . $request->key . '%');
    }

    $doctors = $query->paginate(10);

    foreach ($doctors as $doctor) {
        $doctor->coordinates = $doctor->getCoordinates();
    }

    return response()->json($doctors, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}



    public function show($id)
    {
        $doctor = Doctor::find($id);

        if (!$doctor) {
            return response()->json(['message' => 'Doctor not found'], 404);
        }
    return response()->json([
           $doctor,
        ], 200, [], JSON_INVALID_UTF8_SUBSTITUTE );
    }
    public function getDoctorsSpecialization($categoryID)
    {
        $doctors = Doctor::where("category_id" , $categoryID)->get();
        return response()->json($doctors);
    }
}
