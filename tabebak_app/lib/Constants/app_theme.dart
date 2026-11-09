import 'package:flutter/material.dart';

// Brand palette sampled from the Tabebak (طبيبك) logo.
const Color kBrandDark = Color(0xFF0A3D91);
const Color kBrandPrimary = Color(0xFF1565C0);
const Color kBrandLight = Color(0xFF42A5F5);
const Color kBrandSky = Color(0xFFE3F0FD);
const Color kBrandSurface = Color(0xFFF4F8FD);
const Color kBrandText = Color(0xFF13233F);
const Color kBrandMuted = Color(0xFF6B7A90);
const Color kBrandSuccess = Color(0xFF16A34A);

const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [kBrandDark, kBrandPrimary, kBrandLight],
);

const String kLogoAsset = 'assets/images/tabebak_logo.png';

List<BoxShadow> softShadow([Color color = kBrandPrimary]) => [
      BoxShadow(
        color: color.withValues(alpha: 0.10),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrandPrimary,
    primary: kBrandPrimary,
    secondary: kBrandLight,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: scheme,
    scaffoldBackgroundColor: kBrandSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBrandPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: kBrandPrimary.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBrandSky),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBrandSky, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBrandPrimary, width: 1.6),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: kBrandPrimary),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kBrandDark,
      contentTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeSlideScaleTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Page transition: the new page rises in while fading and scaling up,
/// the old page recedes slightly.
class FadeSlideScaleTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlideScaleTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final exit = CurvedAnimation(
        parent: secondaryAnimation, curve: Curves.easeInOutCubic);

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(enter),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(enter),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 0.95).animate(exit),
            child: child,
          ),
        ),
      ),
    );
  }
}
