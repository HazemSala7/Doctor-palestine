import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatelessWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;

  const FavoritesPage({
    super.key,
    required this.changeTabIndex,
    required this.onLanguageSelected,
  });

  /// Rebuilds a listing from a saved favourite.
  static Place placeFor(FavoriteItem f) =>
      Repository.byId(f.productId) ??
      Place(
        id: f.productId,
        kind: PlaceKind.byName(f.color),
        name: f.name,
        specialty: f.desc.isEmpty ? null : f.desc,
        city: '',
        address: '',
        description: '',
        phone: '',
        coverUrl: f.image.isEmpty ? null : f.image,
      );

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
              child: AuroraBackground(
                colors: const [Color(0xFFD81B60), Color(0xFFFF6E91)],
                child: Stack(
                  children: [
                    const Positioned.fill(child: FloatingBubbles(count: 14)),
                    PositionedDirectional(
                      end: 10,
                      top: topInset + 10,
                      child: const HeartbeatPulse(
                        strength: 0.1,
                        child: Text('💖', style: TextStyle(fontSize: 76)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, topInset + 40, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المفضلة',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900)),
                          Row(
                            children: [
                              CountUp(
                                value: favorites.length,
                                duration: const Duration(milliseconds: 600),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900),
                              ),
                              Text(' عنصر محفوظ • اسحب للحذف',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (favorites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EmptyState(
                    title: 'لا يوجد عناصر في المفضلة',
                    subtitle: 'اضغط على ❤ في أي بطاقة لحفظها هنا',
                  ),
                  ElevatedButton.icon(
                    onPressed: () => changeTabIndex(1),
                    icon: const Icon(Icons.medical_services_rounded),
                    label: const Text('تصفح الأطباء'),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 18, bottom: 130),
              sliver: SliverList.builder(
                itemCount: favorites.length,
                itemBuilder: (context, i) {
                  final f = favorites[i];
                  return FadeSlideIn.item(
                    key: ValueKey(f.productId),
                    index: i,
                    child: Dismissible(
                      key: ValueKey('fav-${f.productId}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => context
                          .read<FavoriteProvider>()
                          .removeFavorite(f.productId),
                      background: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: AlignmentDirectional.centerEnd,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A80), Color(0xFFE53935)]),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('حذف',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(width: 6),
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                      child: PlaceCard(place: placeFor(f)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
