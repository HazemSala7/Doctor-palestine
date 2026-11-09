import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/reviews/review_widgets.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/reviews.dart';
import 'package:flutter/material.dart';

/// Opens the rate sheet for [place] and reports the outcome.
/// Returns true when the review is already published.
Future<bool> writeReview(BuildContext context, Place place, {int myRating = 0}) async {
  final result = await showWriteReviewSheet(
    context,
    kind: place.kind,
    placeId: place.id,
    placeName: place.name,
    initialRating: myRating,
  );
  if (result == null || !context.mounted) return false;
  showMessage(context, result.message);
  return result.published;
}

/// Summary, the latest reviews and the "rate" button on a place's page.
class PlaceReviewsSection extends StatefulWidget {
  final Place place;
  final int delay;

  const PlaceReviewsSection({super.key, required this.place, this.delay = 0});

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  static const _preview = 3;
  ReviewPage? _page;
  String? _error;
  int? _mine;

  Place get p => widget.place;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    MyReviews.ratingFor(p.kind, p.id).then((v) {
      if (mounted) setState(() => _mine = v);
    });
    try {
      final page = await ReviewsApi.list(p.kind, p.id);
      if (mounted) setState(() {
        _page = page;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _write() async {
    await writeReview(context, p, myRating: _mine ?? 0);
    _load();
  }

  void _openAll() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ReviewsPage(place: p)));

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final color = p.kind.colors.first;
    return ReviewsCard(
      delay: widget.delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('التقييمات',
                    style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: kBrandText)),
              ),
              if (page != null && page.total > _preview)
                TextButton(
                  onPressed: _openAll,
                  child: Text('عرض الكل (${page.total})'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null && page == null)
            Row(
              children: [
                const Expanded(
                  child: Text('تعذّر تحميل التقييمات',
                      style: TextStyle(color: kBrandMuted)),
                ),
                TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
              ],
            )
          else if (page == null)
            const SizedBox(height: 120, child: AppLoader())
          else ...[
            if (page.summary.count > 0)
              RatingSummaryView(summary: page.summary, color: color)
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: kStarColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                    'لا توجد تقييمات بعد. شارك تجربتك وساعد غيرك في الاختيار!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.brown.shade600,
                        fontWeight: FontWeight.w700,
                        height: 1.5)),
              ),
            const SizedBox(height: 6),
            for (var i = 0; i < page.items.length && i < _preview; i++)
              ReviewTile(review: page.items[i], color: color),
            const SizedBox(height: 10),
            _WriteButton(mine: _mine, color: color, onTap: _write),
          ],
        ],
      ),
    );
  }
}

class _WriteButton extends StatelessWidget {
  final int? mine;
  final Color color;
  final VoidCallback onTap;

  const _WriteButton({required this.mine, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mine == null ? Icons.rate_review_rounded : Icons.edit_rounded,
                  color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                  mine == null
                      ? 'اكتب تقييمك'
                      : 'عدّل تقييمك (${'★' * mine!})',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 14.5)),
            ],
          ),
        ),
      );
}

/// Every published review of a place, loaded page by page.
class ReviewsPage extends StatefulWidget {
  final Place place;

  const ReviewsPage({super.key, required this.place});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _items = <Review>[];
  ReviewSummary? _summary;
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  int? _mine;

  Place get p => widget.place;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    _mine = await MyReviews.ratingFor(p.kind, p.id);
    _items.clear();
    _page = 0;
    _hasMore = true;
    await _more();
  }

  Future<void> _more() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await ReviewsApi.list(p.kind, p.id, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _summary = page.summary;
        _page = page.page;
        _hasMore = page.hasMore;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _write() async {
    await writeReview(context, p, myRating: _mine ?? 0);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final color = p.kind.colors.first;
    final summary = _summary;
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
                  title: 'التقييمات',
                  subtitle: p.name,
                  emoji: '⭐',
                  colors: p.kind.colors,
                ),
              ),
              if (summary != null)
                SliverToBoxAdapter(
                  child: ReviewsCard(
                    child: RatingSummaryView(summary: summary, color: color),
                  ),
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
                    subtitle: 'كن أول من يشارك تجربته',
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
                                review: _items[i], color: color, divider: i > 0),
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
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GradientButton(
          label: _mine == null ? 'اكتب تقييمك' : 'عدّل تقييمك',
          icon: Icons.rate_review_rounded,
          colors: p.kind.colors,
          onTap: _write,
        ),
      ),
    );
  }
}
