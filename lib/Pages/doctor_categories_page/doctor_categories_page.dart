import 'dart:convert';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Pages/clinics_page/clinics_page.dart';
import 'package:clinic_dr_alla/model/doctor_category_model.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorCategoriesPage extends StatefulWidget {
  @override
  _DoctorCategoriesPageState createState() => _DoctorCategoriesPageState();
}

class _DoctorCategoriesPageState extends State<DoctorCategoriesPage> {
  List<DoctorCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(urlDoctorCategories));
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        setState(() {
          _categories =
              decoded.map((e) => DoctorCategoryModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyCustomAppBar(name: "تخصصات الأطباء"),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClinicsPage(
                          initialCategoryId: category.id,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            category.image,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          category.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
