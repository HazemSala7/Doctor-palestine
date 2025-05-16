import 'dart:io';
import 'package:clinic_dr_alla/Components/custom_massage/custom_massage.dart';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/account-screen/account-screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/categories_screen/categories_screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/clinics_home_page/clinics_home_page.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/favourite_screen/favourite_screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
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
  late PersistentTabController _controller;

  String? languageCode;

  @override
  void initState() {
    super.initState();
    loadData();
    _controller = PersistentTabController(initialIndex: widget.currentIndex);
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    languageCode = prefs.getString('language_code') ?? 'ar';
    setState(() {});
  }

  List<PersistentTabConfig> _tabs(BuildContext context) {
    return [
      PersistentTabConfig(
        screen: MainScreen(
          changeTabIndex: (index) => _changeTab(index),
          onLanguageSelected: widget.onLanguageSelected,
        ),
        item: ItemConfig(
          icon: const Icon(Icons.home),
          title: "الرئيسية",
          activeForegroundColor: kMainColor,
        ),
      ),
      PersistentTabConfig(
        screen: Categories(
          changeTabIndex: (index) => _changeTab(index),
          onLanguageSelected: widget.onLanguageSelected,
        ),
        item: ItemConfig(
          icon: const Icon(Icons.category),
          title: "الأقسام",
          activeForegroundColor: Colors.orange,
        ),
      ),
      PersistentTabConfig(
        screen: ClinicsHomePage(
            languageCode: languageCode ?? "ar",
            changeTabIndex: (index) => _changeTab(index),
            onLanguageSelected: widget.onLanguageSelected),
        item: ItemConfig(
          icon: ImageIcon(AssetImage("assets/images/hospital.png")),
          title: "الأطباء/العيادات",
          activeForegroundColor: Colors.red,
        ),
      ),
      PersistentTabConfig(
        screen: FavoritesPage(
            changeTabIndex: (index) => _changeTab(index),
            onLanguageSelected: widget.onLanguageSelected),
        item: ItemConfig(
          icon: ImageIcon(AssetImage("assets/images/wishlist.png")),
          title: "المفضلة",
          activeForegroundColor: Colors.red,
        ),
      ),
      PersistentTabConfig(
        screen: Profile(
          changeTabIndex: (index) => _changeTab(index),
          onLanguageSelected: widget.onLanguageSelected,
          languageCode: languageCode ?? "ar",
        ),
        item: ItemConfig(
          icon: const Icon(Icons.more_horiz),
          title: "المزيد",
          activeForegroundColor: Colors.blue,
        ),
      ),
    ];
  }

  void _changeTab(int index) {
    _controller.jumpToTab(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: UpgradeAlert(
          barrierDismissible: false,
          dialogStyle: UpgradeDialogStyle.cupertino,
          showIgnore: false,
          showLater: false,
          upgrader: Upgrader(
            // debugLogging: true,
            // debugDisplayAlways: true,
            languageCode: "ar",
            messages: CustomUpgraderMessages(),
            countryCode: "ps",
            minAppVersion: Platform.isIOS ? "1.0.6" : "1.0.6",
          ),
          child: PersistentTabView(
            controller: _controller,
            tabs: _tabs(context),
            navBarBuilder: (navBarConfig) => Style7BottomNavBar(
              navBarConfig: navBarConfig,
            ),
          ),
        ),
      ),
    );
  }
}
