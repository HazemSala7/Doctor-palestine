import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_login_page.dart';
import 'package:clinic_dr_alla/Pages/reviews/review_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/reviews.dart';
import 'package:flutter/material.dart';

/// The signed-in doctor's published reviews; they can reply to each.
class DoctorReviewsPage extends StatefulWidget {
  const DoctorReviewsPage({super.key});

  @override
  State<DoctorReviewsPage> createState() => _DoctorReviewsPageState();
}

class _DoctorReviewsPageState extends State<DoctorReviewsPage> {
  final _items = <Review>[];
  ReviewSummary? _summary;
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    await _more();
  }

  Future<void> _more() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await ReviewsApi.mine(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _summary = page.summary;
        _page = page.page;
        _hasMore = page.hasMore;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        showMessage(context, e.message);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const DoctorLoginPage()));
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reply(Review r) async {
    final updated = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplySheet(review: r),
    );
    if (updated == null || !mounted) return;
    setState(() {
      final i = _items.indexWhere((x) => x.id == updated.id);
      if (i >= 0) _items[i] = updated;
    });
    showMessage(context, updated.reply == null ? 'تم حذف الرد' : 'تم نشر ردك');
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final unanswered = _items.where((r) => r.reply == null).length;
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) _more();
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: GradientPageHeader(
                  title: 'تقييمات المرضى',
                  subtitle: unanswered > 0
                      ? '$unanswered بدون رد • ردّك يظهر للجميع تحت التقييم'
                      : 'ردّك يظهر للجميع تحت التقييم',
                  emoji: '⭐',
                  colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
                ),
              ),
              if (summary != null && summary.count > 0)
                SliverToBoxAdapter(
                  child: ReviewsCard(child: RatingSummaryView(summary: summary)),
                ),
              if (_error != null && _items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(title: 'تعذّر التحميل', subtitle: _error!),
                )
              else if (summary == null)
                const SliverFillRemaining(hasScrollBody: false, child: AppLoader())
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'لا توجد تقييمات بعد',
                    subtitle:
                        'بعد كل زيارة تضغط عليها «تمت الزيارة» يستطيع المريض تقييمك من التطبيق',
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: softShadow(),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          FadeSlideIn.item(
                            index: i % 10,
                            child: ReviewTile(
                              review: _items[i],
                              divider: i > 0,
                              onReply: () => _reply(_items[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_loading && _items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  final Review review;

  const _ReplySheet({required this.review});

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  late final _text = TextEditingController(text: widget.review.reply ?? '');
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save(String reply) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final updated = await ReviewsApi.reply(widget.review.id, reply);
      if (mounted) Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors['reply'] ?? e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('الرد على التقييم',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: kBrandText)),
            const SizedBox(height: 8),
            ReviewTile(review: Review(
              id: r.id,
              name: r.name,
              rating: r.rating,
              comment: r.comment,
              verified: r.verified,
              createdAt: r.createdAt,
            ), divider: false),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: fieldDecoration('ردّك',
                  hint: 'مثال: شكراً لثقتك، نتمنى لك دوام الصحة', error: _error),
            ),
            const SizedBox(height: 8),
            GradientButton(
              label: 'نشر الرد',
              icon: Icons.send_rounded,
              loading: _sending,
              onTap: () {
                if (_text.text.trim().isEmpty) {
                  setState(() => _error = 'اكتب الرد أولاً');
                  return;
                }
                _save(_text.text);
              },
            ),
            if (r.reply != null)
              TextButton(
                onPressed: _sending ? null : () => _save(''),
                child: const Text('حذف الرد',
                    style: TextStyle(color: kCancelledColor)),
              ),
          ],
        ),
      ),
    );
  }
}
