import 'dart:convert';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:clinic_dr_alla/Pages/clinics_page/clinics_page.dart';
import 'package:clinic_dr_alla/model/city_model.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class CitiesPage extends StatefulWidget {
  @override
  _CitiesPageState createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  Future<List<CityModel>> getCities() async {
    try {
      final response = await http.get(Uri.parse(urlCities), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        List decoded = jsonDecode(response.body);
        return decoded.map((json) => CityModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching cities: $e');
      throw Exception('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: SafeArea(
        child: Scaffold(
          appBar: MyCustomAppBar(name: "المدن"),
          body: FutureBuilder<List<CityModel>>(
            future: getCities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SpinKitPulse(color: kMainColor, size: 60),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading cities'),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {});
                        },
                      )
                    ],
                  ),
                );
              } else if (snapshot.hasData) {
                final cities = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: cities.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClinicsPage(
                                initialCityId: city.id,
                              ),
                            ),
                          );
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
                          padding:
                              EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Image.network(
                                  '${city.image}',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                city.name,
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
              } else {
                return Center(child: Text("No cities available"));
              }
            },
          ),
        ),
      ),
    );
  }
}
