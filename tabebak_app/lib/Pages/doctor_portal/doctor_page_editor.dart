import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/photo_field.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/doctor_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _headerColors = [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)];

/// The details patients see on the doctor's page. Pops true once saved.
class DoctorPageEditor extends StatefulWidget {
  const DoctorPageEditor({super.key});

  @override
  State<DoctorPageEditor> createState() => _DoctorPageEditorState();
}

class _DoctorPageEditorState extends State<DoctorPageEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();

  DoctorPageDetails? _details;
  String? _loadError;
  Map<String, String> _errors = const {};
  bool _saving = false;

  int? _categoryId;
  int? _cityId;
  String? _photoUrl;
  String? _pickedPhoto;
  bool _removePhoto = false;
  GeoPoint? _location;
  bool _locationChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _mobile, _address, _description, _facebook, _instagram]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final d = await DoctorPageApi.load();
      if (!mounted) return;
      _name.text = d.name;
      _mobile.text = d.mobile;
      _address.text = d.address;
      _description.text = d.description;
      _facebook.text = d.facebook;
      _instagram.text = d.instagram;
      setState(() {
        _details = d;
        // A dropdown can't hold a value that is no longer on the list.
        _categoryId = d.categories.any((o) => o.id == d.categoryId) ? d.categoryId : null;
        _cityId = d.cities.any((o) => o.id == d.cityId) ? d.cityId : null;
        _photoUrl = d.imageUrl;
        _location = d.location;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        showMessage(context, e.message);
        Navigator.pop(context);
      } else {
        setState(() => _loadError = e.message);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final path = await pickPhotoPath();
    if (path != null && mounted) setState(() => _pickedPhoto = path);
  }

  void _clearPhoto() => setState(() {
        _pickedPhoto = null;
        _photoUrl = null;
        _removePhoto = true;
      });

  Future<void> _pickLocation() async {
    final point = await Navigator.push<GeoPoint>(
      context,
      MaterialPageRoute(builder: (_) => _LocationPage(initial: _location)),
    );
    if (point != null && mounted) {
      setState(() {
        _location = point;
        _locationChanged = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = const {};
    });
    try {
      await DoctorPageApi.save(
        name: _name.text,
        categoryId: _categoryId!,
        cityId: _cityId!,
        mobile: _mobile.text,
        address: _address.text,
        description: _description.text,
        facebook: _facebook.text,
        instagram: _instagram.text,
        photoPath: _pickedPhoto,
        removePhoto: _removePhoto,
        locationChanged: _locationChanged,
        location: _location,
      );
      if (!mounted) return;
      showMessage(context, 'تم حفظ بيانات صفحتك');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      showMessage(context, e.fieldErrors.values.firstOrNull ?? e.message);
      if (e.unauthorized) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const header = GradientPageHeader(
      title: 'بيانات صفحتي',
      subtitle: 'هذه البيانات تظهر للمرضى في صفحتك',
      emoji: '📝',
      colors: _headerColors,
    );
    final details = _details;

    if (details == null) {
      return Scaffold(
        backgroundColor: kBrandSurface,
        body: Column(
          children: [
            header,
            Expanded(
              child: _loadError == null
                  ? const AppLoader()
                  : EmptyState(title: 'تعذّر التحميل', subtitle: _loadError!),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            header,
            SectionCard(
              title: 'الصورة',
              emoji: '🖼️',
              child: Center(
                child: PhotoField(
                  url: _photoUrl,
                  pickedPath: _pickedPhoto,
                  onPick: _pickPhoto,
                  onRemove: _clearPhoto,
                ),
              ),
            ),
            SectionCard(
              title: 'المعلومات الأساسية',
              emoji: '🩺',
              child: Column(
                children: [
                  _field(_name, 'الاسم', 'name',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'أدخل الاسم' : null),
                  _dropdown('التخصص', details.categories, _categoryId, 'category_id',
                      Icons.medical_services_outlined, (v) => setState(() => _categoryId = v)),
                  _dropdown('المدينة', details.cities, _cityId, 'city_id',
                      Icons.location_city_rounded, (v) => setState(() => _cityId = v)),
                  _field(_description, 'نبذة عن الطبيب', 'description', lines: 5),
                ],
              ),
            ),
            SectionCard(
              title: 'التواصل والعنوان',
              emoji: '📞',
              child: Column(
                children: [
                  _field(_mobile, 'رقم الهاتف', 'mobile',
                      hint: '059xxxxxxx',
                      icon: Icons.phone_iphone_rounded,
                      keyboard: TextInputType.phone,
                      ltr: true),
                  _field(_address, 'العنوان', 'address', icon: Icons.place_outlined),
                  _locationRow(),
                ],
              ),
            ),
            SectionCard(
              title: 'روابط التواصل الاجتماعي',
              emoji: '🔗',
              child: Column(
                children: [
                  _field(_facebook, 'فيسبوك', 'facebook_url',
                      hint: 'https://facebook.com/...', icon: Icons.facebook_rounded, ltr: true),
                  _field(_instagram, 'إنستغرام', 'instagram_url',
                      hint: 'https://instagram.com/...', icon: Icons.camera_alt_outlined, ltr: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: GradientButton(
                label: 'حفظ التعديلات',
                icon: Icons.save_rounded,
                loading: _saving,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    String? hint,
    IconData? icon,
    TextInputType? keyboard,
    bool ltr = false,
    int lines = 1,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
          textDirection: ltr ? TextDirection.ltr : null,
          minLines: lines,
          maxLines: lines > 1 ? 10 : 1,
          decoration: fieldDecoration(label, hint: hint, icon: icon, error: _errors[key]),
          validator: validator,
        ),
      );

  Widget _dropdown(
    String label,
    List<NamedOption> options,
    int? value,
    String key,
    IconData icon,
    ValueChanged<int?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          decoration: fieldDecoration(label, icon: icon, error: _errors[key]),
          items: [
            for (final o in options)
              DropdownMenuItem(
                  value: o.id, child: Text(o.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'اختر $label' : null,
        ),
      );

  Widget _locationRow() {
    final set = _location != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: Icon(set ? Icons.check_circle_rounded : Icons.map_outlined),
            label: Text(set ? 'تعديل موقع العيادة' : 'تحديد موقع العيادة على الخريطة',
                overflow: TextOverflow.ellipsis),
          ),
        ),
        if (set)
          IconButton(
            tooltip: 'إزالة الموقع',
            onPressed: () => setState(() {
              _location = null;
              _locationChanged = true;
            }),
            icon: const Icon(Icons.delete_outline_rounded, color: kCancelledColor),
          ),
      ],
    );
  }
}

/// Tap the map to place the clinic's pin. Pops the chosen point.
class _LocationPage extends StatefulWidget {
  final GeoPoint? initial;

  const _LocationPage({this.initial});

  @override
  State<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<_LocationPage> {
  /// Hebron, until a pin exists.
  static const _fallback = LatLng(31.5326, 35.0998);

  late LatLng? _pin = widget.initial == null
      ? null
      : LatLng(widget.initial!.lat, widget.initial!.lng);

  @override
  Widget build(BuildContext context) {
    final pin = _pin;
    return Scaffold(
      appBar: AppBar(title: const Text('اضغط على موقع العيادة')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: pin ?? _fallback, zoom: pin == null ? 12 : 16),
            onTap: (p) => setState(() => _pin = p),
            markers: {
              if (pin != null) Marker(markerId: const MarkerId('clinic'), position: pin),
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: GradientButton(
              label: 'اعتماد هذا الموقع',
              icon: Icons.check_rounded,
              onTap: pin == null
                  ? null
                  : () => Navigator.pop(context, GeoPoint(pin.latitude, pin.longitude)),
            ),
          ),
        ],
      ),
    );
  }
}
