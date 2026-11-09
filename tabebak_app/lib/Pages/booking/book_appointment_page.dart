import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/booking/my_appointments_page.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';

/// Patient picks a day, a free slot and leaves a name and phone.
class BookAppointmentPage extends StatefulWidget {
  final Place place;

  const BookAppointmentPage({super.key, required this.place});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  Availability? _info;
  String? _loadError;
  List<DateTime> _days = [];
  DateTime? _day;
  List<Slot>? _slots;
  String? _time;
  bool _sending = false;
  Map<String, String> _fieldErrors = {};

  Place get p => widget.place;
  List<Color> get _colors => p.kind.colors;

  @override
  void initState() {
    super.initState();
    _load();
    MyBookings.lastPatient().then((last) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = last.$1;
      if (_phone.text.isEmpty) _phone.text = last.$2;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final info = await BookingApi.availability(p.id);
      if (!mounted) return;
      final days = [
        for (var i = 0; i <= info.daysAhead; i++)
          DateTime(info.today.year, info.today.month, info.today.day + i)
      ].where((d) => info.workDays.contains(weekdayIndex(d))).toList();
      setState(() {
        _info = info;
        _days = days;
      });
      if (!info.enabled || days.isEmpty) return;
      // Start on today when something is still free, otherwise the next working day.
      final todayFree = info.slots.any((s) => s.available) &&
          DateUtils.isSameDay(days.first, info.today);
      if (todayFree) {
        setState(() {
          _day = days.first;
          _slots = info.slots;
        });
      } else {
        _selectDay(days.firstWhere((d) => !DateUtils.isSameDay(d, info.today),
            orElse: () => days.first));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() {
      _day = day;
      _slots = null;
      _time = null;
    });
    try {
      final info = await BookingApi.availability(p.id, day);
      // Ignore answers for a day the patient has already moved away from.
      if (mounted && _day == day) setState(() => _slots = info.slots);
    } on ApiException catch (e) {
      if (!mounted || _day != day) return;
      setState(() => _slots = const []);
      showMessage(context, e.message);
    }
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (_time == null) {
      showMessage(context, 'اختر وقت الموعد أولاً');
      return;
    }
    if (!_form.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final booked = await BookingApi.book(
        doctorId: p.id,
        date: _day!,
        time: _time!,
        name: _name.text,
        phone: _phone.text,
        notes: _notes.text,
      );
      if (!mounted) return;
      await _showSuccess(booked);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.fieldErrors);
      showMessage(context, e.message);
      // Someone else took the slot meanwhile: show the fresh picture.
      if (e.fieldErrors.containsKey('time') && _day != null) _selectDay(_day!);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showSuccess(Appointment a) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _SuccessSheet(
          place: p,
          appointment: a,
          onMyAppointments: () {
            Navigator.pop(sheetContext);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const MyAppointmentsPage()));
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: GradientPageHeader(
              title: 'حجز موعد',
              subtitle: p.subtitle == p.kind.label
                  ? p.name
                  : '${p.name} • ${p.subtitle}',
              emoji: '📅',
              colors: _colors,
            ),
          ),
          if (_loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Problem(message: _loadError!, onRetry: _load),
            )
          else if (info == null)
            const SliverFillRemaining(hasScrollBody: false, child: AppLoader())
          else if (!info.enabled || _days.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Problem(
                message: 'الحجز عبر التطبيق غير متاح لهذا الطبيب حالياً',
                actionLabel: p.phone.isEmpty ? null : 'اتصل بالعيادة',
                onRetry: p.phone.isEmpty ? null : () => callNumber(p.phone),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _daysSection()),
            SliverToBoxAdapter(child: _slotsSection()),
            SliverToBoxAdapter(child: _formSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
      bottomNavigationBar:
          info != null && info.enabled && _days.isNotEmpty ? _bottomBar() : null,
    );
  }

  Widget _daysSection() {
    final today = _info!.today;
    return SectionCard(
      title: 'اختر اليوم',
      emoji: '🗓️',
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final d = _days[i];
            final selected = _day != null && DateUtils.isSameDay(d, _day);
            final isToday = DateUtils.isSameDay(d, today);
            return FadeSlideIn.item(
              index: i,
              child: PressableScale(
                onTap: selected ? null : () => _selectDay(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: selected ? p.kind.gradient : null,
                    color: selected ? null : kBrandSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: selected ? Colors.transparent : kBrandSky,
                        width: 1.4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isToday ? 'اليوم' : kWeekdays[weekdayIndex(d)],
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white70 : kBrandMuted)),
                      Text('${d.day}',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: selected ? Colors.white : kBrandText)),
                      Text(monthName(d),
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white70 : kBrandMuted)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _slotsSection() {
    final slots = _slots;
    Widget body;
    if (slots == null) {
      body = Skeleton(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
              8, (_) => const SkeletonBox(width: 86, height: 44, radius: 14)),
        ),
      );
    } else if (!slots.any((s) => s.available)) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text('لا توجد مواعيد متاحة في هذا اليوم، اختر يوماً آخر',
            style: TextStyle(color: kBrandMuted, fontWeight: FontWeight.w600)),
      );
    } else {
      final morning = slots.where((s) => s.time.compareTo('12:00') < 0).toList();
      final evening = slots.where((s) => s.time.compareTo('12:00') >= 0).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morning.isNotEmpty) _slotGroup('☀️ صباحاً', morning),
          if (morning.isNotEmpty && evening.isNotEmpty) const SizedBox(height: 12),
          if (evening.isNotEmpty) _slotGroup('🌙 مساءً', evening),
        ],
      );
    }
    return SectionCard(
      title: 'اختر الوقت',
      emoji: '🕒',
      delay: 80,
      trailing: _day == null
          ? null
          : Text(formatDay(_day!),
              style: const TextStyle(
                  color: kBrandMuted, fontSize: 12.5, fontWeight: FontWeight.w700)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.topCenter,
        child: body,
      ),
    );
  }

  Widget _slotGroup(String title, List<Slot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: kBrandMuted, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in slots)
              PressableScale(
                onTap: s.available ? () => setState(() => _time = s.time) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 86,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _time == s.time ? p.kind.gradient : null,
                    color: _time == s.time
                        ? null
                        : s.available
                            ? Colors.white
                            : const Color(0xFFF1F3F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _time == s.time
                            ? Colors.transparent
                            : s.available
                                ? kBrandSky
                                : Colors.transparent,
                        width: 1.4),
                  ),
                  child: Text(
                    formatTime(s.time),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: _time == s.time
                          ? Colors.white
                          : s.available
                              ? kBrandText
                              : const Color(0xFFB0B8C4),
                      decoration:
                          s.available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _formSection() {
    return SectionCard(
      title: 'بيانات المريض',
      emoji: '🧑',
      delay: 160,
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration('الاسم الكامل',
                  icon: Icons.person_outline_rounded,
                  error: _fieldErrors['patient_name']),
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'اكتب اسم المريض' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              decoration: fieldDecoration('رقم الهاتف',
                  hint: '059xxxxxxx',
                  icon: Icons.phone_iphone_rounded,
                  error: _fieldErrors['patient_phone']),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 9 || digits.length > 15
                    ? 'رقم الهاتف غير صحيح'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              maxLength: 500,
              decoration: fieldDecoration('ملاحظات للطبيب (اختياري)',
                  hint: 'سبب الزيارة أو أي معلومة تهم الطبيب',
                  icon: Icons.notes_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: kBrandDark.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _time == null || _day == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Text('🗓️ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                              '${formatDay(_day!)} • ${formatTime(_time!)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: kBrandText)),
                        ),
                      ],
                    ),
                  ),
          ),
          GradientButton(
            label: 'تأكيد الحجز',
            icon: Icons.event_available_rounded,
            loading: _sending,
            colors: _colors,
            onTap: _time == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  const _Problem({required this.message, this.actionLabel, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: FadeSlideIn(
        fromScale: 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FloatingWidget(
                distance: 8, child: Text('🗓️', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: kBrandText)),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: GradientButton(
                  label: actionLabel ?? 'إعادة المحاولة',
                  icon: actionLabel == null
                      ? Icons.refresh_rounded
                      : Icons.call_rounded,
                  onTap: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final Place place;
  final Appointment appointment;
  final VoidCallback onMyAppointments;

  const _SuccessSheet({
    required this.place,
    required this.appointment,
    required this.onMyAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
                color: kBrandSky, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 18),
          const FadeSlideIn(
            fromScale: 0.4,
            child: HeartbeatPulse(
              strength: 0.06,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFE8F7EE),
                child: Icon(Icons.check_rounded, color: kBrandSuccess, size: 54),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('تم إرسال طلب الحجز',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w900, color: kBrandText)),
          const SizedBox(height: 6),
          const Text('سيؤكد الطبيب موعدك، وتستطيع متابعة حالته من «مواعيدي»',
              textAlign: TextAlign.center,
              style: TextStyle(color: kBrandMuted, fontSize: 14, height: 1.6)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBrandSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                PlaceAvatar(place: place, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: kBrandText)),
                      const SizedBox(height: 2),
                      Text(
                          '${formatDay(appointment.date)} • ${formatTime(appointment.time)}',
                          style: const TextStyle(
                              color: kBrandMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                StatusBadge(appointment.status),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'مواعيدي',
            icon: Icons.event_note_rounded,
            onTap: onMyAppointments,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
