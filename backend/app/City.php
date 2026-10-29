<?php

namespace App;

use Illuminate\Database\Eloquent\Model;


class City extends Model
{
        public function getImageAttribute($value)
    {
        return url('/') . '/storage/' . $value;
    }
    
}
