import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/reviews/review_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/reviews.dart';
import 'package:flutter/material.dart';

/// Bookings made from this phone, with their live status.
class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  List<Appointment>? _items;
  String? _error;
  final _cancelling = <String>{};

  /// Doctor id => stars this phone gave them.
  final _ratings = <int, int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await MyBookings.load();
      for (final id in {for (final a in items) a.doctorId}) {
        final r = await MyReviews.ratingFor(PlaceKind.doctor, id);
        if (r != null) _ratings[id] = r;
      }
      if (mounted) setState(() {
        _items = items;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _cancel(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إلغاء الموعد؟'),
        content: Text(
            'سيتم إلغاء موعدك مع ${a.doctorName ?? 'الطبيب'} يوم ${formatDay(a.date)} الساعة ${formatTime(a.time)}.'),
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
    if (ok != true || !mounted) return;

    setState(() => _cancelling.add(a.code!));
    try {
      final updated = await BookingApi.cancel(a.code!);
      if (!mounted) return;
      setState(() => _items = [
            for (final i in _items!) i.code == a.code ? updated : i
          ]);
      showMessage(context, 'تم إلغاء الموعد');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _cancelling.remove(a.code));
    }
  }

  Future<void> _review(Appointment a) async {
    final result = await showWriteReviewSheet(
      context,
      kind: PlaceKind.doctor,
      placeId: a.doctorId,
      placeName: a.doctorName ?? 'الطبيب',
      appointmentCode: a.code,
      initialRating: _ratings[a.doctorId] ?? 0,
    );
    if (result == null || !mounted) return;
    setState(() => _ratings[a.doctorId] = result.review.rating);
    showMessage(context, result.message);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final upcoming = items?.where((a) => a.isUpcoming && a.isActive).toList() ?? [];
    final past = items?.where((a) => !(a.isUpcoming && a.isActive)).toList() ?? [];

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(
              child: GradientPageHeader(
                title: 'مواعيدي',
                subtitle: 'الحجوزات التي قمت بها من هذا الهاتف',
                emoji: '📅',
                colors: [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
              ),
            ),
            if (_error != null && items == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(title: 'تعذّر التحميل', subtitle: _error!),
              )
            else if (items == null)
              const SliverFillRemaining(hasScrollBody: false, child: AppLoader())
            else if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'لا توجد مواعيد بعد',
                  subtitle: 'افتح صفحة طبيب واضغط «احجز موعدك» لحجز أول موعد',
                ),
              )
            else ...[
              if (upcoming.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: SectionHeader(title: 'القادمة', emoji: '⏰')),
                _list(upcoming),
              ],
              if (past.isNotEmpty) ...[
                const SliverToBoxAdapter(
                    child: SectionHeader(title: 'السابقة والملغاة', emoji: '🗂️')),
                _list(past),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _list(List<Appointment> items) => SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) => FadeSlideIn.item(
          index: i,
          child: _AppointmentCard(
            appointment: items[i],
            cancelling: _cancelling.contains(items[i].code),
            onCancel: () => _cancel(items[i]),
            myRating: _ratings[items[i].doctorId],
            onReview: () => _review(items[i]),
          ),
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool cancelling;
  final VoidCallback onCancel;
  final int? myRating;
  final VoidCallback onReview;

  const _AppointmentCard({
    required this.appointment,
    required this.cancelling,
    required this.onCancel,
    required this.onReview,
    this.myRating,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final faded = !a.isActive || !a.isUpcoming;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(statusColor(a.status)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: a.doctorImage != null && a.doctorImage!.isNotEmpty
                      ? NetImage(a.doctorImage!, fit: BoxFit.cover)
                      : Container(
                          color: kBrandSky,
                          alignment: Alignment.center,
                          child: const Text('🩺', style: TextStyle(fontSize: 26)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.doctorName ?? 'طبيب',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: kBrandText)),
                    const SizedBox(height: 4),
                    Text('${formatDay(a.date)} • ${formatTime(a.time)}',
                        style: TextStyle(
                            color: faded ? kBrandMuted : kBrandPrimary,
                            fontWeight: FontWeight.w800)),
                    if (a.patientName.isNotEmpty)
                      Text('المريض: ${a.patientName}',
                          style: const TextStyle(
                              color: kBrandMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusBadge(a.status),
            ],
          ),
          if (a.isActive && a.isUpcoming) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if ((a.doctorPhone ?? '').isNotEmpty)
                  Expanded(
                    child: _SmallAction(
                      label: 'اتصل بالعيادة',
                      icon: Icons.call_rounded,
                      color: kBrandSuccess,
                      onTap: () => callNumber(a.doctorPhone!),
                    ),
                  ),
                if ((a.doctorPhone ?? '').isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: _SmallAction(
                    label: cancelling ? 'جارٍ الإلغاء...' : 'إلغاء الموعد',
                    icon: Icons.event_busy_rounded,
                    color: kCancelledColor,
                    onTap: cancelling ? null : onCancel,
                  ),
                ),
              ],
            ),
          ],
          // After the doctor marks the visit done, the patient can rate it.
          if (a.status == AppointmentStatus.completed) ...[
            const SizedBox(height: 12),
            _SmallAction(
              label: myRating == null
                  ? 'قيّم زيارتك ⭐'
                  : 'تقييمك ${'★' * myRating!} • تعديل',
              icon: myRating == null
                  ? Icons.rate_review_rounded
                  : Icons.edit_rounded,
              color: const Color(0xFFB28704),
              onTap: onReview,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallAction(
      {required this.label, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
