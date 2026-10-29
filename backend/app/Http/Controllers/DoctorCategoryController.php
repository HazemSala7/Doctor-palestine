<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\DoctorCategory;

class DoctorCategoryController extends Controller
{
    public function index()
    {
        $categories = DoctorCategory::all();
        return response()->json($categories);
    }
}
