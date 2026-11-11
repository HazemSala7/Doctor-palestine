import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_login_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_page_editor.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_reels_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_team_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_reviews_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_schedule_page.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:flutter/material.dart';

/// Confirms with the password before the doctor's account is deleted.
/// Pops with the number of cancelled bookings once it's gone.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'اكتب كلمة المرور لتأكيد الحذف');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cancelled = await DoctorApi.deleteAccount(_password.text);
      if (mounted) Navigator.pop(context, cancelled);
    } on ApiException catch (e) {
      if (mounted)
        setState(() => _error = e.fieldErrors['password'] ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget point(String emoji, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: kBrandText, fontSize: 13.5, height: 1.5)),
              ),
            ],
          ),
        );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: kCancelledColor),
          SizedBox(width: 8),
          Expanded(child: Text('حذف حسابي نهائياً')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            point('🗑️',
                'يُحذف حسابك: رقم الدخول وكلمة المرور وإعدادات المواعيد.'),
            point('⛔', 'يتوقف استقبال الحجوزات عبر التطبيق.'),
            point('📅', 'تُلغى الحجوزات القادمة، ويرى المرضى أنها أُلغيت.'),
            point('ℹ️',
                'تبقى صفحتك في دليل الأطباء. لحذفها أيضاً تواصل معنا عبر الدعم.'),
            const SizedBox(height: 4),
            const Text('لا يمكن التراجع عن هذا.',
                style: TextStyle(
                    color: kCancelledColor, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              onSubmitted: (_) => _delete(),
              decoration: fieldDecoration('كلمة المرور للتأكيد', error: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kCancelledColor),
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white))
              : const Text('احذف حسابي'),
        ),
      ],
    );
  }
}

enum _Scope {
  upcoming('القادمة'),
  today('اليوم'),
  past('السابقة');

  final String label;
  const _Scope(this.label);
}

/// The signed-in doctor's bookings, grouped by day.
class DoctorDashboardPage extends StatefulWidget {
  final DoctorProfile? profile;

  const DoctorDashboardPage({super.key, this.profile});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage>
    with WidgetsBindingObserver {
  DoctorProfile? _profile;
  _Scope _scope = _Scope.upcoming;
  final _lists = <_Scope, List<Appointment>>{};
  AppointmentSummary? _summary;
  String? _error;
  final _busy = <int>{};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    WidgetsBinding.instance.addObserver(this);
    if (_profile == null) _loadProfile();
    _load();
    // New bookings show up without pulling to refresh.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        showMessage(context, e.message);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DoctorLoginPage()));
      } else if (_lists[_scope] == null) {
        setState(() => _error = e.message);
      } else {
        showMessage(context, e.message);
      }
    }
  }

  Future<void> _loadProfile() => _guard(() async {
        final p = await DoctorApi.me();
        if (mounted) setState(() => _profile = p);
      });

  Future<void> _load() => _guard(() async {
        final scope = _scope;
        final (items, summary) = await DoctorApi.appointments(scope.name);
        if (!mounted) return;
        setState(() {
          _lists[scope] = items;
          _summary = summary;
          _error = null;
        });
      });

  void _switch(_Scope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _load();
  }

  Future<void> _setStatus(Appointment a, AppointmentStatus status) async {
    if (status == AppointmentStatus.cancelled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('إلغاء الموعد؟'),
          content: Text(
              'سيظهر للمريض ${a.patientName} أن موعده يوم ${formatDay(a.date)} الساعة ${formatTime(a.time)} أُلغي.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('تراجع')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('إلغاء الموعد',
                  style: TextStyle(color: kCancelledColor)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy.add(a.id));
    await _guard(() async {
      final updated = await DoctorApi.setStatus(a.id, status);
      if (!mounted) return;
      setState(() {
        for (final s in _lists.keys) {
          _lists[s] = [for (final i in _lists[s]!) i.id == a.id ? updated : i];
        }
      });
      showMessage(context, 'تم تحديث الموعد: ${updated.status.label}');
      _load(); // refresh the counters
    });
    if (mounted) setState(() => _busy.remove(a.id));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('تراجع')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('خروج')),
        ],
      ),
    );
    if (ok != true) return;
    await DoctorApi.logout();
    if (mounted) Navigator.pop(context);
  }

  /// Asks for the password, says plainly what goes and what stays, then
  /// deletes the account and leaves the portal.
  Future<void> _deleteAccount() async {
    final cancelled = await showDialog<int>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (cancelled == null || !mounted) return;
    showMessage(
        context,
        cancelled > 0
            ? 'تم حذف حسابك، وأُلغي $cancelled من الحجوزات القادمة'
            : 'تم حذف حسابك');
    Navigator.pop(context);
  }

  Future<void> _openSchedule() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.push<DoctorProfile>(
      context,
      MaterialPageRoute(builder: (_) => DoctorSchedulePage(profile: profile)),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  /// Comes back through [_loadProfile], which also catches an expired session.
  Future<void> _openManaged(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final items = _lists[_scope];
    final profile = _profile;

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: GradientPageHeader(
                title: profile?.name ?? 'لوحة الطبيب',
                subtitle: profile?.specialty ?? 'مواعيد العيادة',
                emoji: '🩺',
                colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
                actions: [
                  GlassButton(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DoctorReviewsPage())),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.white, size: 22),
                  ),
                  GlassButton(
                    onTap: _openSchedule,
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 21),
                  ),
                  GlassButton(
                    onTap: _logout,
                    child: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
                bottom: _summaryRow(),
              ),
            ),
            if (profile != null && !profile.schedule.bookingEnabled)
              SliverToBoxAdapter(child: _bookingOffBanner()),
            SliverToBoxAdapter(child: _managePage()),
            SliverToBoxAdapter(child: _tabs()),
            if (_error != null && items == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(title: 'تعذّر التحميل', subtitle: _error!),
              )
            else if (items == null)
              const SliverFillRemaining(
                  hasScrollBody: false, child: AppLoader())
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: switch (_scope) {
                    _Scope.today => 'لا مواعيد اليوم',
                    _Scope.upcoming => 'لا توجد حجوزات قادمة',
                    _Scope.past => 'لا توجد مواعيد سابقة',
                  },
                  subtitle: 'تظهر هنا الحجوزات التي يقوم بها المرضى من التطبيق',
                ),
              )
            else
              ..._grouped(items),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow() {
    final s = _summary;
    Widget pill(String label, int? value, String emoji) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text(value == null ? '–' : '$value',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                Text('$emoji $label',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        pill('اليوم', s?.today, '📍'),
        const SizedBox(width: 8),
        pill('بانتظار التأكيد', s?.pending, '⏳'),
        const SizedBox(width: 8),
        pill('مؤكدة', s?.confirmed, '✅'),
      ],
    );
  }

  Widget _managePage() {
    Widget tile(String title, String subtitle, IconData icon, Widget page) =>
        Expanded(
          child: PressableScale(
            pressedScale: 0.97,
            onTap: () => _openManaged(page),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: kBrandPrimary, size: 26),
                  const SizedBox(height: 8),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: kBrandText)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kBrandMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile('بيانات صفحتي', 'الاسم والصورة والعنوان والروابط',
                  Icons.edit_note_rounded, const DoctorPageEditor()),
              const SizedBox(width: 10),
              tile('طاقم العمل', 'إضافة وتعديل وحذف الموظفين',
                  Icons.groups_rounded, const DoctorTeamPage()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              tile('الريلز', 'إضافة الفيديوهات وتعديلها وإخفاؤها وحذفها',
                  Icons.smart_display_rounded, const DoctorReelsPage()),
              const SizedBox(width: 10),
              Expanded(
                child: PressableScale(
                  pressedScale: 0.97,
                  onTap: _deleteAccount,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCancelledColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: kCancelledColor.withValues(alpha: 0.25)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person_remove_rounded,
                            color: kCancelledColor, size: 26),
                        SizedBox(height: 8),
                        Text('حذف حسابي',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kCancelledColor)),
                        Text('حذف حساب الطبيب نهائياً من التطبيق',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: kBrandMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingOffBanner() => PressableScale(
        pressedScale: 0.97,
        onTap: _openSchedule,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPendingColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Text('⏸️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'استقبال الحجوزات متوقف حالياً، المرضى لا يرون زر الحجز. اضغط لتفعيله.',
                    style: TextStyle(
                        color: kPendingColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(),
      ),
      child: Row(
        children: [
          for (final s in _Scope.values)
            Expanded(
              child: PressableScale(
                pressedScale: 0.96,
                onTap: () => _switch(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: s == _scope ? kBrandGradient : null,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(s.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: s == _scope ? Colors.white : kBrandMuted)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _grouped(List<Appointment> items) {
    final today = DateUtils.dateOnly(DateTime.now());
    final out = <Widget>[];
    DateTime? current;
    var index = 0;
    for (final a in items) {
      if (current == null || !DateUtils.isSameDay(current, a.date)) {
        current = a.date;
        final diff = a.date.difference(today).inDays;
        final relative = switch (diff) {
          0 => ' • اليوم',
          1 => ' • غداً',
          -1 => ' • أمس',
          _ => '',
        };
        out.add(SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text('${formatDay(a.date)}$relative',
                style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: kBrandText)),
          ),
        ));
      }
      out.add(SliverToBoxAdapter(
        child: FadeSlideIn.item(
          index: index++,
          child: _DoctorAppointmentCard(
            appointment: a,
            busy: _busy.contains(a.id),
            onStatus: (s) => _setStatus(a, s),
          ),
        ),
      ));
    }
    return out;
  }
}

class _DoctorAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool busy;
  final ValueChanged<AppointmentStatus> onStatus;

  const _DoctorAppointmentCard({
    required this.appointment,
    required this.busy,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final color = statusColor(a.status);
    final parts = formatTime(a.time).split(' ');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(color),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: const BorderRadiusDirectional.horizontal(
                        start: Radius.circular(24))
                    .resolve(Directionality.of(context)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(parts[0],
                      style: TextStyle(
                          color: color,
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  Text(parts[1],
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: kBrandText)),
                        ),
                        StatusBadge(a.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(a.patientPhone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                color: kBrandMuted,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _IconAction(Icons.call_rounded, kBrandSuccess,
                            () => callNumber(a.patientPhone)),
                        const SizedBox(width: 6),
                        _IconAction(
                            Icons.chat_rounded,
                            const Color(0xFF25D366),
                            () => openWhatsApp(a.patientPhone,
                                'مرحباً ${a.patientName}، بخصوص موعدك يوم ${formatDay(a.date)} الساعة ${formatTime(a.time)}')),
                      ],
                    ),
                    if ((a.notes ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBrandSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('📝 ${a.notes}',
                            style: const TextStyle(
                                color: Color(0xFF3B4A63), height: 1.5)),
                      ),
                    ],
                    if (a.isActive) ...[
                      const SizedBox(height: 10),
                      busy
                          ? const Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4)))
                          : Row(
                              children: [
                                if (a.status == AppointmentStatus.pending)
                                  _action(
                                      'تأكيد',
                                      Icons.check_rounded,
                                      kBrandSuccess,
                                      AppointmentStatus.confirmed)
                                else
                                  _action(
                                      'تمت الزيارة',
                                      Icons.done_all_rounded,
                                      kBrandPrimary,
                                      AppointmentStatus.completed),
                                const SizedBox(width: 8),
                                _action(
                                    'إلغاء',
                                    Icons.close_rounded,
                                    kCancelledColor,
                                    AppointmentStatus.cancelled),
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
          String label, IconData icon, Color color, AppointmentStatus to) =>
      Expanded(
        child: PressableScale(
          onTap: () => onStatus(to),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      );
}
