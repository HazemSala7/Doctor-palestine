<?php

namespace App;

use Illuminate\Database\Eloquent\Model;
use TCG\Voyager\Traits\Spatial;

class Pharmacy extends Model
{
    use Spatial;

    protected $spatial = ['coordinates'];

    public function city()
    {
        return $this->belongsTo(City::class);
    }

    public function getLogoImageAttribute($value)
    {
        if (!$value) return null;

        return strpos($value, 'http') === 0
            ? $value
            : url('/') . '/storage/' . ltrim($value, '/');
    }

    public function getCoverImageAttribute($value)
    {
        if (!$value) return null;

        return strpos($value, 'http') === 0
            ? $value
            : url('/') . '/storage/' . ltrim($value, '/');
    }
}


