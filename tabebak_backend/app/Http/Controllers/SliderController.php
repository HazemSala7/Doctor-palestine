<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Slider;
use App\Advertisement;

class SliderController extends Controller
{
public function index()
{
    $sliders = Slider::all();
    $advertisement = Advertisement::first(); // This gets the first row

    return response()->json([
        'sliders' => $sliders,
        'advertisement' => $advertisement,
    ]);
}

}
