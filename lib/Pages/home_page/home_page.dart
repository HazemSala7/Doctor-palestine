import 'dart:io';

import 'package:clinic_dr_alla/Components/custom_massage/custom_massage.dart';
import 'package:clinic_dr_alla/Components/tabebak_nav_bar.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/account-screen/account-screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/favourite_screen/favourite_screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/main_screen.dart';
import 'package:clinic_dr_alla/Pages/places/places_page.dart';
import 'package:clinic_dr_alla/Pages/search/search_page.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  final int currentIndex;
  final Function(String) onLanguageSelected;

  HomeScreen({
    Key? key,
    required this.currentIndex,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index = widget.currentIndex.clamp(0, 3);
  final Set<int> _visited = {};
  String? languageCode;

  @override
  void initState() {
    super.initState();
    _visited.add(_index);
    loadData();
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString('language_code') ?? 'ar';
    setState(() {});
  }

  void _changeTab(int index) {
    setState(() {
      _index = index.clamp(0, 3);
      _visited.add(_index);
    });
  }

  void _openSearch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SearchPage(),
        transitionsBuilder: (_, a, __, child) {
          final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(c),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _tab(int i) {
    switch (i) {
      case 0:
        return MainScreen(
          changeTabIndex: _changeTab,
          onLanguageSelected: widget.onLanguageSelected,
          onSearch: _openSearch,
        );
      case 1:
        return const PlacesPage(kind: PlaceKind.doctor, embedded: true);
      case 2:
        return FavoritesPage(
          changeTabIndex: _changeTab,
          onLanguageSelected: widget.onLanguageSelected,
        );
      default:
        return Profile(
          changeTabIndex: _changeTab,
          onLanguageSelected: widget.onLanguageSelected,
          languageCode: languageCode ?? 'ar',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favCount =
        context.select<FavoriteProvider, int>((f) => f.favorites.length);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: UpgradeAlert(
        barrierDismissible: false,
        dialogStyle: UpgradeDialogStyle.cupertino,
        showIgnore: false,
        showLater: false,
        upgrader: Upgrader(
          languageCode: "ar",
          messages: CustomUpgraderMessages(),
          countryCode: "ps",
          minAppVersion: Platform.isIOS ? "1.0.6" : "1.0.6",
        ),
        child: Scaffold(
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < 4; i++)
                if (_visited.contains(i))
                  IgnorePointer(
                    ignoring: i != _index,
                    // Only the visible tab may run animations or fly heroes;
                    // tabs share one route, so duplicate hero tags would clash.
                    // The fade must sit outside TickerMode, or a tab being
                    // hidden would freeze mid-fade and stay on screen.
                    child: HeroMode(
                      enabled: i == _index,
                      child: AnimatedOpacity(
                        opacity: i == _index ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        child: AnimatedSlide(
                          offset:
                              i == _index ? Offset.zero : const Offset(0, 0.02),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: TickerMode(
                            enabled: i == _index,
                            child: _tab(i),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
          bottomNavigationBar: TabebakNavBar(
            currentIndex: _index,
            onTap: _changeTab,
            onCenterTap: _openSearch,
            items: [
              const NavItem(
                  Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
              const NavItem(Icons.medical_services_outlined,
                  Icons.medical_services_rounded, 'الأطباء'),
              NavItem(Icons.favorite_border_rounded, Icons.favorite_rounded,
                  'المفضلة',
                  badge: favCount),
              const NavItem(
                  Icons.grid_view_outlined, Icons.grid_view_rounded, 'المزيد'),
            ],
          ),
        ),
      ),
    );
  }
}
