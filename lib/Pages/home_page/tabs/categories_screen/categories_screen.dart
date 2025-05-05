import 'dart:convert';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:clinic_dr_alla/Pages/cities_page/cities_page.dart';
import 'package:clinic_dr_alla/Pages/clinics_page/clinics_page.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/categories_screen/category_grid/category_grid.dart';
import 'package:clinic_dr_alla/Pages/hospitals_page/hospitals_page.dart';
import 'package:clinic_dr_alla/Pages/laboratories_page/laboratories_page.dart';
import 'package:clinic_dr_alla/Pages/pharmacies_page/pharmacies_page.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Categories extends StatefulWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  const Categories(
      {Key? key,
      required this.changeTabIndex,
      required this.onLanguageSelected})
      : super(key: key);

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("الأقسام الرئيسية ",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              switch (category['id']) {
                case '1':
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CitiesPage()));
                  break;
                case '2':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ClinicsPage()));
                  break;
                case '3':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => HospitalsPage()));
                  break;
                case '4':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PharmaciesPage()));
                  break;
                case '5':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LaboratoriesPage()));
                  break;
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      category['image']!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    category['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
