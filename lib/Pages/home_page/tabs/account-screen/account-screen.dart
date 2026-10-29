import 'dart:io';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/about_us/about_us.dart';
import 'package:clinic_dr_alla/Pages/explore/explore_pages.dart';
import 'package:clinic_dr_alla/Pages/privacy_policy/privacy_policy.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

/// The "More" tab.
class Profile extends StatelessWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  final String languageCode;

  const Profile({
    Key? key,
    required this.changeTabIndex,
    required this.onLanguageSelected,
    required this.languageCode,
  }) : super(key: key);

  Future<void> _whatsApp() async {
    const contact = "+972594606276";
    const text = 'مرحباً، أحتاج مساعدة بخصوص تطبيق طبيبك';
    final url = Platform.isIOS
        ? "https://wa.me/$contact?text=${Uri.encodeComponent(text)}"
        : "whatsapp://send?phone=$contact&text=${Uri.encodeComponent(text)}";
    try {
      await launchUrl(Uri.parse(url));
    } on Exception {
      Fluttertoast.showToast(msg: "WhatsApp is not installed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(40)),
            child: AuroraBackground(
              colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
              child: Stack(
                children: [
                  const Positioned.fill(child: FloatingBubbles(count: 16)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topInset + 30, 20, 30),
                    child: Column(
                      children: [
                        FadeSlideIn(
                          fromScale: 0.6,
                          child: HeartbeatPulse(
                            strength: 0.04,
                            child: Container(
                              width: 210,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: kBrandDark.withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child:
                                  ShimmerSweep(child: Image.asset(kLogoAsset)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('دليلك الطبي الشامل في فلسطين',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('الإصدار 1.5.0',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _group('استكشف', [
            _Tile('🗺️', 'المدن', const Color(0xFF0D47A1),
                () => push(const CitiesScreen())),
            _Tile('🩺', 'التخصصات الطبية', const Color(0xFF3949AB),
                () => push(const SpecialtiesScreen())),
            _Tile('💼', 'وظائف القطاع الطبي', const Color(0xFFEF6C00),
                () => push(const JobsScreen())),
            _Tile('❤️', 'المفضلة', const Color(0xFFD81B60),
                () => changeTabIndex(2)),
          ]),
          _group('عن التطبيق', [
            _Tile('ℹ️', 'من نحن', kBrandPrimary, () => push(WhoWeAre())),
            _Tile('🔒', 'سياسة الخصوصية', const Color(0xFF546E7A),
                () => push(Privacy())),
            _Tile('💬', 'تواصل معنا عبر واتساب', const Color(0xFF25D366),
                _whatsApp),
          ]),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _social('assets/images/facebook.png', const Color(0xFF1877F2),
                    'https://www.facebook.com/profile.php?id=61563302551082'),
                _social('assets/images/instagram.png', const Color(0xFFE1306C),
                    'https://www.instagram.com/yolo_beauty.ps?igsh=MXc5d2lkOTBmZjA3bA'),
                PressableScale(
                  onTap: _whatsApp,
                  child: _socialCircle(
                      'assets/images/whatsapp.png', const Color(0xFF25D366)),
                ),
              ],
            ),
          ),
          if (kUseDemoData)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(
                child: Text('🧪 التطبيق يعمل حالياً على بيانات تجريبية',
                    style: TextStyle(
                        color: Color(0xFFEF6C00),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _social(String asset, Color color, String url) => PressableScale(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: _socialCircle(asset, color),
      );

  Widget _socialCircle(String asset, Color color) => Container(
        width: 54,
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Image.asset(asset),
      );

  Widget _group(String title, List<_Tile> tiles) {
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Text(title,
                  style: const TextStyle(
                      color: kBrandMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            for (var i = 0; i < tiles.length; i++)
              FadeSlideIn.item(index: i, child: tiles[i]),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Tile(this.emoji, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.97,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: kBrandText)),
            ),
            Icon(Icons.chevron_left_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
