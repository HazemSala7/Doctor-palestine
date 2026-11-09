import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:flutter/material.dart';

const _slotLengths = [10, 15, 20, 30, 45, 60, 90, 120];

/// Working days, hours and slot length. Pops the saved [DoctorProfile].
class DoctorSchedulePage extends StatefulWidget {
  final DoctorProfile profile;

  const DoctorSchedulePage({super.key, required this.profile});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  late bool _enabled = widget.profile.schedule.bookingEnabled;
  late final Set<int> _days = {...widget.profile.schedule.workDays};
  late String _start = widget.profile.schedule.workStart;
  late String _end = widget.profile.schedule.workEnd;
  late int _slot = widget.profile.schedule.slotMinutes;
  bool _saving = false;

  DoctorSchedule get _schedule => DoctorSchedule(
        bookingEnabled: _enabled,
        workDays: _days,
        workStart: _start,
        workEnd: _end,
        slotMinutes: _slot,
      );

  Future<void> _pickTime(bool start) async {
    final current = (start ? _start : _end).split(':').map(int.parse).toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current[0], minute: current[1]),
      helpText: start ? 'بداية الدوام' : 'نهاية الدوام',
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      showMessage(context, 'اختر يوم عمل واحداً على الأقل');
      return;
    }
    if (_schedule.slotsPerDay == 0) {
      showMessage(context, 'نهاية الدوام يجب أن تكون بعد بدايته بمدة موعد على الأقل');
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = await DoctorApi.saveSchedule(_schedule);
      if (!mounted) return;
      showMessage(context, 'تم حفظ أوقات العمل');
      Navigator.pop(context, profile);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) showMessage(context, 'تم تغيير كلمة المرور');
  }

  String _slotLabel(int m) => m < 60
      ? '$m دقيقة'
      : m == 60
          ? 'ساعة'
          : m == 90
              ? 'ساعة ونصف'
              : 'ساعتان';

  @override
  Widget build(BuildContext context) {
    final perDay = _schedule.slotsPerDay;
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          const GradientPageHeader(
            title: 'أوقات العمل',
            subtitle: 'يختار المرضى من هذه الأوقات عند الحجز',
            emoji: '⏰',
            colors: [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
          ),
          FadeSlideIn(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: softShadow(),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('استقبال الحجوزات عبر التطبيق',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: kBrandText)),
                subtitle: Text(
                    _enabled
                        ? 'يظهر زر «احجز موعدك» في صفحتك'
                        : 'متوقف: لا يستطيع المرضى الحجز حالياً',
                    style: const TextStyle(color: kBrandMuted, fontSize: 12.5)),
              ),
            ),
          ),
          SectionCard(
            title: 'أيام العمل',
            emoji: '📆',
            delay: 60,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var d = 0; d < 7; d++)
                  PressableScale(
                    onTap: () => setState(
                        () => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _days.contains(d) ? kBrandGradient : null,
                        color: _days.contains(d) ? null : kBrandSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(kWeekdays[d],
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _days.contains(d)
                                  ? Colors.white
                                  : kBrandMuted)),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: 'ساعات الدوام',
            emoji: '🕒',
            delay: 120,
            child: Row(
              children: [
                Expanded(child: _timeTile('من', _start, () => _pickTime(true))),
                const SizedBox(width: 10),
                Expanded(child: _timeTile('إلى', _end, () => _pickTime(false))),
              ],
            ),
          ),
          SectionCard(
            title: 'مدة الموعد',
            emoji: '⏱️',
            delay: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _slotLengths)
                      PressableScale(
                        onTap: () => setState(() => _slot = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: _slot == m ? kBrandGradient : null,
                            color: _slot == m ? null : kBrandSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_slotLabel(m),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _slot == m ? Colors.white : kBrandMuted)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (perDay == 0 ? kCancelledColor : kBrandSuccess)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    perDay == 0
                        ? 'لا يوجد وقت كافٍ لموعد واحد بين بداية الدوام ونهايته'
                        : 'سيتاح للمرضى $perDay ${perDay <= 10 && perDay > 2 ? 'مواعيد' : 'موعداً'} في كل يوم عمل',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: perDay == 0 ? kCancelledColor : kBrandSuccess),
                  ),
                ),
              ],
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: GradientButton(
                label: 'حفظ أوقات العمل',
                icon: Icons.save_rounded,
                loading: _saving,
                onTap: _save,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: TextButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('تغيير كلمة المرور',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String value, VoidCallback onTap) =>
      PressableScale(
        pressedScale: 0.96,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kBrandSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBrandSky, width: 1.4),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: kBrandMuted)),
              Text(formatTime(value),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kBrandPrimary)),
            ],
          ),
        ),
      );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _errors = {});
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DoctorApi.changePassword(_current.text, _next.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errors =
            e.fieldErrors.isEmpty ? {'current_password': e.message} : e.fieldErrors);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة المرور'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: fieldDecoration('كلمة المرور الحالية',
                  error: _errors['current_password']),
              validator: (v) => (v ?? '').isEmpty ? 'مطلوبة' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: fieldDecoration('كلمة المرور الجديدة',
                  error: _errors['password']),
              validator: (v) =>
                  (v ?? '').length < 6 ? '6 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: fieldDecoration('تأكيد كلمة المرور'),
              validator: (v) => v != _next.text ? 'غير متطابقة' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء')),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
