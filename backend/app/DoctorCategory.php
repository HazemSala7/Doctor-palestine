<?php

namespace App;

use Illuminate\Database\Eloquent\Model;


class DoctorCategory extends Model
{
        public function getImageAttribute($value)
{
    if (strpos($value, 'http') === 0) {
        return $value; // already a full URL
    }

    return url('/') . '/storage/' . $value;
}
}
