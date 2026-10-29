<?php

namespace App;

use Illuminate\Database\Eloquent\Model;
use TCG\Voyager\Traits\Spatial;
use App\City;
use App\DoctorCategory;

class Doctor extends Model
{
    use Spatial;

    protected $spatial = ['coordinates'];

    public function getImageAttribute($value)
{
    if (strpos($value, 'http') === 0) {
        return $value; // already a full URL
    }

    return url('/') . '/storage/' . $value;
}


    public function city()
    {
        return $this->belongsTo(City::class);
    }

    public function category()
    {
        return $this->belongsTo(DoctorCategory::class);
    }
}

