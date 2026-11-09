import 'dart:ui';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
}

/// Floating glass navigation bar: a gradient blob slides to the active tab,
/// and a raised glowing search button sits in the middle.
class TabebakNavBar extends StatelessWidget {
  final List<NavItem> items; // exactly 4; the centre slot is the action
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const TabebakNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  }) : assert(items.length == 4);

  static const double height = 72;

  int _slotOf(int index) => index < 2 ? index : index + 1;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: SizedBox(
        height: height + 26,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Glass body.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandDark.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      child: LayoutBuilder(builder: (context, c) {
                        final slotW = c.maxWidth / 5;
                        final dir = Directionality.of(context);
                        final slot = _slotOf(currentIndex);
                        final start = slot * slotW + (slotW - 58) / 2;
                        return Stack(
                          children: [
                            // Sliding blob.
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 520),
                              curve: Curves.easeOutBack,
                              top: 8,
                              left: dir == TextDirection.ltr ? start : null,
                              right: dir == TextDirection.rtl ? start : null,
                              width: 58,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: kBrandGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          kBrandPrimary.withValues(alpha: 0.45),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var slot = 0; slot < 5; slot++)
                                  Expanded(
                                    child: slot == 2
                                        ? const SizedBox()
                                        : _item(slot < 2 ? slot : slot - 1),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            // Raised centre button.
            Positioned(
              top: 0,
              child: PressableScale(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onCenterTap();
                },
                child: HeartbeatPulse(
                  strength: 0.06,
                  period: const Duration(milliseconds: 2200),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00C6FF), kBrandPrimary, kBrandDark],
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: kBrandPrimary.withValues(alpha: 0.55),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(int index) {
    final item = items[index];
    final active = index == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!active) HapticFeedback.selectionClick();
        onTap(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                    active ? item.activeIcon : item.icon,
                    key: ValueKey(active),
                    color: active ? Colors.white : kBrandMuted,
                    size: 25,
                  ),
                ),
              ),
              if (item.badge > 0)
                PositionedDirectional(
                  top: -6,
                  end: -10,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(item.badge),
                    tween: Tween(begin: 0.3, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3D6E),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text('${item.badge}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              height: 1.1,
              color: active ? Colors.white : kBrandMuted,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
