<?php

namespace App\FormFields;

use TCG\Voyager\FormFields\AbstractHandler;

class AdvertisementTargetFormField extends AbstractHandler
{
    protected $codename = 'advertisement_target';

    public function createContent($row, $dataType, $dataTypeContent, $options)
    {
        return view('vendor.voyager.formfields.advertisement_target', [
            'row' => $row,
            'dataType' => $dataType,
            'dataTypeContent' => $dataTypeContent,
            'options' => $options,
        ]);
    }
}
