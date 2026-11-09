<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Doctor;
use App\Services\Booking;

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

    $bookable = Booking::enabledDoctorIds($doctors->pluck('id'));
    foreach ($doctors as $doctor) {
        $doctor->coordinates = $doctor->getCoordinates();
        $doctor->booking_enabled = in_array((int) $doctor->id, $bookable, true);
    }

    return response()->json($doctors, 200, [], JSON_INVALID_UTF8_SUBSTITUTE);
}



    public function show($id)
    {
        $doctor = Doctor::find($id);

        if (!$doctor) {
            return response()->json(['message' => 'Doctor not found'], 404);
        }
        $doctor->booking_enabled = in_array((int) $doctor->id, Booking::enabledDoctorIds([$doctor->id]), true);
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
