<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Advertisement extends Model
{
    protected $fillable = ['title', 'image', 'type', 'target_id', 'active', 'start_date', 'end_date'];

    public function getTargetTypeAttribute()
    {
        return explode('_', $this->target_id)[0] ?? null;
    }

    public function getTargetRealIdAttribute()
    {
        return explode('_', $this->target_id)[1] ?? null;
    }

public function getTargetLabelAttribute()
{
    $type = $this->target_type;
    $id = $this->target_real_id;

    if (!$type || !$id) return null;

    if ($type === 'hospital') {
        return optional(\App\Models\Hospital::find($id))->name ?? 'N/A';
    }

    if ($type === 'pharmacy') {
        return optional(\App\Models\Pharmacy::find($id))->name ?? 'N/A';
    }

    if ($type === 'doctor') {
        return optional(\App\Models\Doctor::find($id))->name ?? 'N/A';
    }

    if ($type === 'lab') {
        return optional(\App\Models\Laboratory::find($id))->name ?? 'N/A';
    }

    if ($type === 'radiology') {
        return optional(\App\Models\RadiologyCenter::find($id))->name ?? 'N/A';
    }

    if ($type === 'beauty_center') {
        return optional(\App\Models\BeautyCenter::find($id))->name ?? 'N/A';
    }

    if ($type === 'warehouse') {
        return optional(\App\Models\MedicalWarehouse::find($id))->name ?? 'N/A';
    }

    if ($type === 'nutrition') {
        return optional(\App\Models\NutritionCenter::find($id))->name ?? 'N/A';
    }

    if ($type === 'optic') {
        return optional(\App\Models\Optic::find($id))->name ?? 'N/A';
    }

    if ($type === 'treatment_center') {
        return optional(\App\Models\MedicalTreatmentCenter::find($id))->name ?? 'N/A';
    }

    if ($type === 'job') {
        return optional(\App\Models\Job::find($id))->name ?? 'N/A';
    }

    if ($type === 'city') {
        return optional(\App\Models\City::find($id))->name ?? 'N/A';
    }

    return 'N/A';
}

}
