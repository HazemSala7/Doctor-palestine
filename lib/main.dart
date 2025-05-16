import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const Clinics());
}

class Clinics extends StatefulWidget {
  const Clinics({super.key});

  @override
  State<Clinics> createState() => _ClinicsState();
  static _ClinicsState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ClinicsState>();
}

class _ClinicsState extends State<Clinics> {
  Locale locale = Locale('ar', 'AE');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Future<void> setLocale(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    setState(() {
      locale = Locale(languageCode);
    });

    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) => HomeScreen(
            currentIndex: 0,
            onLanguageSelected: setLocale,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => FavoriteProvider()..loadFavorites()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ar', 'AE'),
        ],
        locale: locale,
        debugShowCheckedModeBanner: false,
        title: 'Attendify',
        theme: ThemeData(
          fontFamily: 'Cairo',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: HomeScreen(currentIndex: 0, onLanguageSelected: setLocale),
      ),
    );
  }
}
