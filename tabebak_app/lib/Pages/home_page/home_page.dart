import 'dart:io';

import 'package:clinic_dr_alla/Components/custom_massage/custom_massage.dart';
import 'package:clinic_dr_alla/Components/tabebak_nav_bar.dart';
import 'package:clinic_dr_alla/Pages/ads/premium_ad_window.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/account-screen/account-screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/main_screen.dart';
import 'package:clinic_dr_alla/Pages/places/places_page.dart';
import 'package:clinic_dr_alla/Pages/reels/reels_screen.dart';
import 'package:clinic_dr_alla/Pages/search/search_page.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _minRefreshGap = Duration(seconds: 10);

  late int _index = widget.currentIndex.clamp(0, 3);
  final Set<int> _visited = {};
  String? languageCode;

  /// Goes up each time the tabs should re-read the dashboard's data.
  int _refreshTick = 0;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visited.add(_index);
    loadData();
    // A running premium ad opens once the home screen has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) maybeShowPremiumAd(context);
      });
    });
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString('language_code') ?? 'ar';
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshFromDashboard();
  }

  /// Dashboard edits reach an open app when the user returns to it or
  /// switches tab.
  Future<void> _refreshFromDashboard() async {
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < _minRefreshGap) return;
    _lastRefresh = now;
    await Repository.reloadConfig();
    if (mounted) setState(() => _refreshTick++);
  }

  void _changeTab(int index) {
    setState(() {
      _index = index.clamp(0, 3);
      _visited.add(_index);
    });
    _refreshFromDashboard();
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
          refreshTick: _refreshTick,
        );
      case 1:
        return PlacesPage(
            kind: PlaceKind.doctor, embedded: true, refreshTick: _refreshTick);
      case 2:
        return ReelsScreen(active: _index == 2, refreshTick: _refreshTick);
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
              const NavItem(Icons.play_circle_outline_rounded,
                  Icons.play_circle_fill_rounded, 'ريلز'),
              const NavItem(
                  Icons.grid_view_outlined, Icons.grid_view_rounded, 'المزيد'),
            ],
          ),
        ),
      ),
    );
  }
}
