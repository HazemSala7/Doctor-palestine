import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:flutter/material.dart';

/// Gradient page header with a back button, a big title and a floating emoji.
class GradientPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;

  /// Glass buttons shown opposite the back button.
  final List<Widget> actions;

  /// Extra content under the subtitle.
  final Widget? bottom;
  final bool showBack;

  const GradientPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    this.actions = const [],
    this.bottom,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: AuroraBackground(
        colors: colors,
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles(count: 12)),
            PositionedDirectional(
              end: 18,
              top: topInset + (actions.isEmpty ? 4 : 58),
              child: FloatingWidget(
                distance: 8,
                child: Text(emoji, style: const TextStyle(fontSize: 58)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        GlassButton(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 19),
                        )
                      else
                        const SizedBox(height: 44),
                      const Spacer(),
                      for (final a in actions) ...[
                        const SizedBox(width: 8),
                        a,
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    offset: const Offset(0.2, 0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 70),
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    offset: const Offset(0.2, 0),
                    child: Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14)),
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: 18),
                    FadeSlideIn(
                        delay: const Duration(milliseconds: 200), child: bottom!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
