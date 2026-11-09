import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/photo_field.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/doctor_page.dart';
import 'package:flutter/material.dart';

/// The doctor adds, edits, hides, orders and removes their team.
class DoctorTeamPage extends StatefulWidget {
  const DoctorTeamPage({super.key});

  @override
  State<DoctorTeamPage> createState() => _DoctorTeamPageState();
}

class _DoctorTeamPageState extends State<DoctorTeamPage> {
  List<TeamMember>? _team;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final team = await DoctorPageApi.team();
      if (mounted) {
        setState(() {
          _team = team;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  void _fail(ApiException e) {
    if (!mounted) return;
    if (e.unauthorized) {
      showMessage(context, e.message);
      Navigator.pop(context);
    } else if (_team == null) {
      setState(() => _error = e.message);
    } else {
      showMessage(context, e.message);
    }
  }

  Future<void> _edit([TeamMember? member]) async {
    final changed = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _MemberSheet(member: member),
    );
    if (changed == null || !mounted) return;
    showMessage(context, changed);
    _load();
  }

  Future<void> _move(int from, int to) async {
    final list = [..._team!];
    final moved = list.removeAt(from);
    list.insert(to > from ? to - 1 : to, moved);
    setState(() => _team = list);
    try {
      await DoctorPageApi.reorder([for (final m in list) m.id]);
    } on ApiException catch (e) {
      _fail(e);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final canReorder = (team?.length ?? 0) > 1;
    final header = GradientPageHeader(
      title: 'طاقم العمل',
      subtitle: canReorder
          ? 'اضغط على الموظف لتعديله، واسحب ☰ لتغيير الترتيب'
          : 'يظهر هذا الفريق للمرضى في صفحتك',
      emoji: '👥',
      colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
    );

    return Scaffold(
      backgroundColor: kBrandSurface,
      floatingActionButton: team == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _edit,
              backgroundColor: kBrandPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('إضافة موظف'),
            ),
      body: team == null || team.isEmpty
          ? Column(
              children: [
                header,
                Expanded(
                  child: team != null
                      ? const EmptyState(
                          title: 'لا يوجد موظفون بعد',
                          subtitle: 'أضف فريق عيادتك ليظهر للمرضى في صفحتك',
                        )
                      : _error != null
                          ? EmptyState(title: 'تعذّر التحميل', subtitle: _error!)
                          : const AppLoader(),
                ),
              ],
            )
          : ReorderableListView.builder(
              header: header,
              padding: const EdgeInsets.only(bottom: 100),
              buildDefaultDragHandles: false,
              itemCount: team.length,
              onReorder: _move,
              itemBuilder: (_, i) => _tile(team[i], i, canReorder),
            ),
    );
  }

  Widget _tile(TeamMember m, int index, bool canReorder) => Container(
        key: ValueKey(m.id),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _edit(m),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Opacity(opacity: m.active ? 1 : 0.45, child: _avatar(m)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: kBrandText)),
                        Text(m.active ? m.role : '${m.role} • مخفي عن المرضى',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: m.active ? kBrandMuted : kPendingColor,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  if (canReorder)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.menu_rounded, color: kBrandMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _avatar(TeamMember m) {
    const icon = Icon(Icons.person_rounded, color: kBrandPrimary);
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: kBrandSky, shape: BoxShape.circle),
      child: m.imageUrl == null
          ? icon
          : Image.network(m.imageUrl!,
              fit: BoxFit.cover, errorBuilder: (_, __, ___) => icon),
    );
  }
}

/// Add or edit one member. Pops the message to show after a change.
class _MemberSheet extends StatefulWidget {
  final TeamMember? member;

  const _MemberSheet({this.member});

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name);
  late final _role = TextEditingController(text: widget.member?.role);
  late final _bio = TextEditingController(text: widget.member?.bio);
  late bool _active = widget.member?.active ?? true;
  late String? _photoUrl = widget.member?.imageUrl;
  String? _picked;
  bool _removePhoto = false;
  bool _busy = false;
  String? _error;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final path = await pickPhotoPath();
    if (path != null && mounted) setState(() => _picked = path);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _error = null;
      _errors = const {};
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, done);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _busy = false;
        _errors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final m = widget.member;
    _run(
      () => DoctorPageApi.saveMember(
        id: m?.id,
        name: _name.text,
        role: _role.text,
        bio: _bio.text,
        active: _active,
        photoPath: _picked,
        removePhoto: _removePhoto,
      ),
      m == null ? 'تمت إضافة الموظف' : 'تم حفظ التعديلات',
    );
  }

  Future<void> _delete() async {
    final m = widget.member!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('حذف ${m.name}؟'),
        content: const Text('لن يظهر بعدها في صفحتك، ولا يمكن التراجع عن الحذف.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف', style: TextStyle(color: kCancelledColor)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _run(() => DoctorPageApi.deleteMember(m.id), 'تم حذف الموظف');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.member != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(editing ? 'تعديل بيانات الموظف' : 'إضافة موظف',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: kBrandText)),
              const SizedBox(height: 14),
              PhotoField(
                size: 88,
                url: _photoUrl,
                pickedPath: _picked,
                onPick: _pick,
                onRemove: () => setState(() {
                  _picked = null;
                  _photoUrl = null;
                  _removePhoto = true;
                }),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                maxLength: 80,
                decoration: fieldDecoration('الاسم',
                    icon: Icons.badge_outlined, error: _errors['name']),
                validator: (v) => (v ?? '').trim().isEmpty ? 'أدخل الاسم' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _role,
                maxLength: 80,
                decoration: fieldDecoration('الوظيفة',
                    hint: 'ممرضة العيادة',
                    icon: Icons.work_outline_rounded,
                    error: _errors['role']),
                validator: (v) => (v ?? '').trim().isEmpty ? 'أدخل الوظيفة' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bio,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                decoration: fieldDecoration('نبذة (اختياري)', error: _errors['bio']),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('يظهر للمرضى في صفحتي',
                    style: TextStyle(fontWeight: FontWeight.w800, color: kBrandText)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: kCancelledColor, fontWeight: FontWeight.w700)),
                ),
              GradientButton(
                label: editing ? 'حفظ التعديلات' : 'إضافة',
                icon: Icons.save_rounded,
                loading: _busy,
                onTap: _busy ? null : _save,
              ),
              if (editing)
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded, color: kCancelledColor),
                  label: const Text('حذف الموظف', style: TextStyle(color: kCancelledColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
