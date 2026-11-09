import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/reviews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kStarColor = Color(0xFFFFB300);

const _starWords = ['', 'سيئ', 'مقبول', 'جيد', 'جيد جداً', 'ممتاز'];

/// Big average, stars and a bar per star level.
class RatingSummaryView extends StatelessWidget {
  final ReviewSummary summary;
  final Color color;

  const RatingSummaryView(
      {super.key, required this.summary, this.color = kBrandPrimary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Column(
            children: [
              s.average == null
                  ? const Text('–',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: kBrandText))
                  : CountUp(
                      value: s.average!,
                      decimals: 1,
                      style: const TextStyle(
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: kBrandText),
                    ),
              const SizedBox(height: 4),
              StarRating(rating: s.average ?? 0, size: 17),
              const SizedBox(height: 4),
              Text(
                  s.count == 0
                      ? 'لا تقييمات بعد'
                      : s.count == 1
                          ? 'تقييم واحد'
                          : '${s.count} تقييم',
                  style: const TextStyle(color: kBrandMuted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text('$stars',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: kBrandMuted)),
                      ),
                      const Icon(Icons.star_rounded, size: 13, color: kStarColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: s.share(stars)),
                            duration: Duration(milliseconds: 500 + stars * 90),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              backgroundColor: kBrandSky,
                              valueColor: const AlwaysStoppedAnimation(kStarColor),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text('${s.breakdown[stars] ?? 0}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 11.5, color: kBrandMuted)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One review with its reply. [onReply] adds the doctor's reply button.
class ReviewTile extends StatelessWidget {
  final Review review;
  final Color color;
  final VoidCallback? onReply;
  final bool divider;

  const ReviewTile({
    super.key,
    required this.review,
    this.color = kBrandPrimary,
    this.onReply,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = review;
    final initial = r.name.trim().isEmpty ? '؟' : r.name.trim().characters.first;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: Color(0xFFE8EEF6)))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(initial,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: kBrandText)),
                        ),
                        if (r.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedVisitBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        StarRating(rating: r.rating.toDouble(), size: 14),
                        const SizedBox(width: 6),
                        Text(formatAgo(r.createdAt),
                            style: const TextStyle(
                                color: kBrandMuted, fontSize: 11.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment != null) ...[
            const SizedBox(height: 8),
            Text(r.comment!,
                style: const TextStyle(
                    height: 1.6, color: Color(0xFF3B4A63), fontSize: 13.5)),
          ],
          if (r.reply != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(16),
                  bottomStart: Radius.circular(16),
                  bottomEnd: Radius.circular(16),
                  topStart: Radius.circular(4),
                ),
                border: BorderDirectional(
                    start: BorderSide(color: color, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text('الرد',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5)),
                      const Spacer(),
                      Text(formatAgo(r.repliedAt),
                          style: const TextStyle(
                              color: kBrandMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(r.reply!,
                      style: const TextStyle(
                          height: 1.55, color: kBrandText, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (onReply != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onReply,
                icon: Icon(
                    r.reply == null ? Icons.reply_rounded : Icons.edit_rounded,
                    size: 18),
                label: Text(r.reply == null ? 'رُدّ على التقييم' : 'تعديل الرد'),
              ),
            ),
        ],
      ),
    );
  }
}

class VerifiedVisitBadge extends StatelessWidget {
  const VerifiedVisitBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: kBrandSuccess.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 13, color: kBrandSuccess),
            SizedBox(width: 3),
            Text('زيارة مؤكدة',
                style: TextStyle(
                    color: kBrandSuccess,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

/// Tappable stars that pop when picked.
class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarPicker(
      {super.key, required this.value, required this.onChanged, this.size = 46});

  @override
  Widget build(BuildContext context) {
    // Star 1 sits at the start (the right in Arabic).
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedScale(
                  scale: i == value ? 1.25 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                      i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(i <= value),
                      size: size,
                      color: i <= value ? kStarColor : const Color(0xFFC7D2E0),
                    ),
                  ),
                ),
              ),
            ),
        ],
    );
  }
}

/// Opens the "rate" sheet. Returns the result once sent, null if closed.
/// [appointmentCode] marks the review as a verified visit.
Future<ReviewResult?> showWriteReviewSheet(
  BuildContext context, {
  required PlaceKind kind,
  required int placeId,
  required String placeName,
  String? appointmentCode,
  int initialRating = 0,
}) =>
    showModalBottomSheet<ReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        kind: kind,
        placeId: placeId,
        placeName: placeName,
        appointmentCode: appointmentCode,
        initialRating: initialRating,
      ),
    );

class _WriteReviewSheet extends StatefulWidget {
  final PlaceKind kind;
  final int placeId;
  final String placeName;
  final String? appointmentCode;
  final int initialRating;

  const _WriteReviewSheet({
    required this.kind,
    required this.placeId,
    required this.placeName,
    this.appointmentCode,
    this.initialRating = 0,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating = widget.initialRating;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  final _tags = <String>{};
  Map<String, String> _errors = {};
  bool _sending = false;

  List<String> get _quickTags => widget.kind == PlaceKind.doctor
      ? const ['تعامل راقٍ', 'شرح واضح', 'التزام بالموعد', 'تشخيص دقيق', 'سعر مناسب', 'عيادة نظيفة']
      : const ['خدمة سريعة', 'تعامل راقٍ', 'مكان نظيف', 'أسعار مناسبة', 'موظفون متعاونون', 'سهولة الوصول'];

  @override
  void initState() {
    super.initState();
    MyBookings.lastPatient().then((p) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = p.$1;
      if (_phone.text.isEmpty) _phone.text = p.$2;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0) {
      setState(() => _errors = {'rating': 'اختر عدد النجوم أولاً'});
      return;
    }
    final comment = [
      if (_tags.isNotEmpty) _tags.join(' • '),
      if (_comment.text.trim().isNotEmpty) _comment.text.trim(),
    ].join('\n');
    setState(() {
      _sending = true;
      _errors = {};
    });
    try {
      final result = await ReviewsApi.submit(
        kind: widget.kind,
        id: widget.placeId,
        rating: _rating,
        name: _name.text,
        phone: _phone.text,
        comment: comment,
        appointmentCode: widget.appointmentCode,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty ||
          e.fieldErrors.containsKey('appointment_code')) {
        showMessage(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.kind.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, 20 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DEEA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                  widget.appointmentCode != null
                      ? 'كيف كانت زيارتك؟'
                      : 'قيّم ${widget.kind == PlaceKind.doctor ? 'الطبيب' : widget.kind.label}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: kBrandText)),
              const SizedBox(height: 2),
              Text(widget.placeName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.first, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              StarPicker(
                value: _rating,
                onChanged: (v) => setState(() {
                  _rating = v;
                  _errors.remove('rating');
                }),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _errors['rating'] ??
                      (_rating == 0 ? 'اضغط على النجوم' : _starWords[_rating]),
                  key: ValueKey('$_rating${_errors['rating']}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _errors['rating'] != null
                        ? kCancelledColor
                        : _rating == 0
                            ? kBrandMuted
                            : const Color(0xFFB28704),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in _quickTags)
                    FilterChip(
                      label: Text(t),
                      selected: _tags.contains(t),
                      onSelected: (on) =>
                          setState(() => on ? _tags.add(t) : _tags.remove(t)),
                      showCheckmark: false,
                      selectedColor: colors.first.withValues(alpha: 0.14),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: _tags.contains(t) ? colors.first : kBrandMuted,
                      ),
                      side: BorderSide(
                          color: _tags.contains(t)
                              ? colors.first
                              : const Color(0xFFDDE5EF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comment,
                maxLines: 4,
                minLines: 3,
                maxLength: 900,
                textInputAction: TextInputAction.newline,
                decoration: fieldDecoration('اكتب تجربتك (اختياري)',
                    hint: 'ما الذي أعجبك؟ وما الذي يمكن تحسينه؟',
                    error: _errors['comment']),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: fieldDecoration('اسمك كما سيظهر مع التقييم',
                    icon: Icons.person_rounded, error: _errors['name']),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: fieldDecoration('رقم الهاتف',
                    hint: '059xxxxxxx',
                    icon: Icons.phone_rounded,
                    error: _errors['phone']),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: kBrandMuted),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        'رقمك لا يظهر لأحد، ويضمن تقييماً واحداً لكل شخص.',
                        style: TextStyle(color: kBrandMuted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'إرسال التقييم',
                icon: Icons.send_rounded,
                loading: _sending,
                colors: colors.length > 1 ? colors : const [kBrandDark, kBrandPrimary],
                onTap: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card wrapper used by the details page's reviews section.
class ReviewsCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const ReviewsCard({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) => FadeSlideIn(
        delay: Duration(milliseconds: delay),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: softShadow(kStarColor),
          ),
          child: child,
        ),
      );
}
