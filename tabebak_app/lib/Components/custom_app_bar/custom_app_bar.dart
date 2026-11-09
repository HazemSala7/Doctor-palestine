import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';

class MyCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final List<Widget>? actions;
  final bool showBack;

  const MyCustomAppBar({
    Key? key,
    required this.name,
    this.actions,
    this.showBack = true,
  }) : super(key: key);

  static const _radius = BorderRadius.vertical(bottom: Radius.circular(26));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(borderRadius: _radius),
      flexibleSpace: ClipRRect(
        borderRadius: _radius,
        child: Container(
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            boxShadow: softShadow(kBrandDark),
          ),
          child: const FloatingBubbles(count: 10),
        ),
      ),
      leading: !showBack
          ? null
          : Padding(
              padding: const EdgeInsets.all(8),
              child: PressableScale(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
      title: FadeSlideIn(
        offset: const Offset(0, 0.4),
        child: Text(
          name,
          style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      elevation: 0,
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
