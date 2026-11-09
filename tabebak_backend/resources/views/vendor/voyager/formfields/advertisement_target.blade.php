@php
    $selected = $dataTypeContent->target_id ?? '';
@endphp

<div>
    <select id="target-type" class="form-control">
        <option value="">-- Select Type --</option>
        @foreach([
            'hospital' => 'Hospital',
            'pharmacy' => 'Pharmacy',
            'doctor' => 'Doctor',
            'lab' => 'Laboratory',
            'radiology' => 'Radiology Center',
            'beauty_center' => 'Beauty Center',
            'warehouse' => 'Medical Warehouse',
            'nutrition' => 'Nutrition Center',
            'optic' => 'Optic',
            'treatment_center' => 'Treatment Center',
            'job' => 'Job',
            'city' => 'City'
        ] as $key => $label)
            <option value="{{ $key }}" {{ old('type', $dataTypeContent->type ?? '') == $key ? 'selected' : '' }}>{{ $label }}</option>
        @endforeach
    </select>

    <br>

    <select name="target_id" id="target-id" class="form-control">
        <option value="">-- Select Target --</option>
    </select>
</div>

<script>
    async function loadTargets(type, selected = null) {
        const basePath = window.location.pathname.includes('/clinics_backend') ? '/clinics_backend' : '';
const res = await fetch(`${basePath}/admin/advertisement-targets/${type}`);

        const data = await res.json();

        const targetSelect = document.getElementById('target-id');
        targetSelect.innerHTML = '';

        data.forEach(item => {
            const option = document.createElement('option');
            option.value = item.id;
            option.text = item.name;
            if (selected && selected == item.id) option.selected = true;
            targetSelect.appendChild(option);
        });
    }

    document.addEventListener("DOMContentLoaded", function () {
        const typeSelect = document.getElementById('target-type');
        const selectedType = typeSelect.value;
        const selectedTarget = "{{ $selected }}";

        if (selectedType) {
            loadTargets(selectedType, selectedTarget);
        }

        typeSelect.addEventListener('change', function () {
            loadTargets(this.value);
        });
    });
</script>
