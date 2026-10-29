<?php

namespace App;

use Illuminate\Database\Eloquent\Model;


class Slider extends Model
{
    public function getImageAttribute($value)
    {
        return url('/') . '/storage/' . $value;
    }
}
