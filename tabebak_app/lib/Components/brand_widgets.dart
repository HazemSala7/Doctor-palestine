import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-page branded loading indicator.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: BrandLoader(logoAsset: kLogoAsset, color: kBrandPrimary),
      );
}

/// Network image that fades in, shows a soft placeholder while loading,
/// and falls back to a branded tile instead of an error box.
class NetImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final BoxFit? fit;

  const NetImage(this.url, {super.key, this.height, this.width, this.fit});

  Widget _placeholder({required bool failed}) => Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [kBrandSky, Colors.white],
          ),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all((height ?? 80) * 0.18),
        child: failed
            ? Opacity(
                opacity: 0.55,
                child: Image.asset(kLogoAsset, fit: BoxFit.contain),
              )
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      frameBuilder: (context, child, frame, wasSync) {
        if (wasSync) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: frame == null ? _placeholder(failed: false) : child,
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(failed: true),
    );
  }
}

/// Shown when a list has finished loading with no results.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.title = 'لا توجد نتائج حالياً',
    this.subtitle = 'جرّب اختيار مدينة أخرى أو عد لاحقاً',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          fromScale: 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingWidget(
                distance: 10,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      kBrandLight.withValues(alpha: 0.22),
                      kBrandSky,
                    ]),
                  ),
                  child: const Icon(Icons.search_off_rounded,
                      size: 56, color: kBrandPrimary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kBrandText),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kBrandMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
