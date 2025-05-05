import 'package:clinic_dr_alla/Components/slide_image/slide_image.dart';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:clinic_dr_alla/Pages/beauty_centers_page/beauty_centers_page.dart';
import 'package:clinic_dr_alla/Pages/cities_page/cities_page.dart';
import 'package:clinic_dr_alla/Pages/clinics_page/clinics_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_categories_page/doctor_categories_page.dart';
import 'package:clinic_dr_alla/Pages/hospitals_page/hospitals_page.dart';
import 'package:clinic_dr_alla/Pages/jobs_page/jobs_page.dart';
import 'package:clinic_dr_alla/Pages/laboratories_page/laboratories_page.dart';
import 'package:clinic_dr_alla/Pages/medical_treatment_centers_page/medical_treatment_centers_page.dart';
import 'package:clinic_dr_alla/Pages/medical_warehouses_page/medical_warehouses_page.dart';
import 'package:clinic_dr_alla/Pages/nutrition_centers_page/nutrition_centers_page.dart';
import 'package:clinic_dr_alla/Pages/optics_page/optics_page.dart';
import 'package:clinic_dr_alla/Pages/pharmacies_page/pharmacies_page.dart';
import 'package:clinic_dr_alla/Pages/radiology_centers_page/radiology_centers_page.dart';
import 'package:clinic_dr_alla/model/slider_model.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  MainScreen(
      {Key? key,
      required this.changeTabIndex,
      required this.onLanguageSelected})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

int current = 0;

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String languageCode = "ar";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString('language_code') ?? 'ar';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        await getSliders();
        setState(() {});
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                FutureBuilder(
                    future: getSliders(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: SpinKitPulse(
                            color: kMainColor,
                            size: 60,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          height: MediaQuery.of(context).size.height,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Center(child: Text("Error"))),
                                SizedBox(height: 10),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        getSliders();
                                      });
                                    },
                                    icon: Icon(Icons.refresh))
                              ],
                            ),
                          ),
                        );
                      } else {
                        List<SliderModel>? album = [];
                        if (snapshot.data != null) {
                          List mysslide = snapshot.data;
                          album = mysslide.map((s) {
                            SliderModel c = SliderModel.fromJson(s);
                            return c;
                          }).toList();

                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                    ),
                                    Text(
                                      "دليل الأطباء",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Image.asset(
                                        "assets/images/logo.png",
                                        fit: BoxFit.cover,
                                        height: 50,
                                        // width: 70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(),
                                    width: double.infinity,
                                    height: 200,
                                    child: ClipRRect(
                                      child: SlideImage(
                                        slideimage: album,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: categories.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
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
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      CitiesPage()));
                                          break;
                                        case '2':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      ClinicsPage()));
                                          break;
                                        case '6':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      DoctorCategoriesPage()));
                                          break;
                                        case '3':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      HospitalsPage()));
                                          break;
                                        case '4':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      PharmaciesPage()));
                                          break;
                                        case '5':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      LaboratoriesPage()));
                                          break;
                                        case '7':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      RadiologyCentersPage()));
                                          break;
                                        case '8':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      BeautyCentersPage()));
                                          break;
                                        case '9':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      MedicalWarehousesPage()));
                                          break;
                                        case '10':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      NutritionCentersPage()));
                                          break;
                                        case '11':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      OpticsPage()));
                                          break;
                                        case '12':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      MedicalTreatmentCentersPage()));
                                          break;
                                        case '13':
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => JobsPage()));
                                          break;
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 80,
                                            width: 80,
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF5F6FA),
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                              SizedBox(
                                height: 20,
                              )
                            ],
                          );
                        } else {
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.25,
                            width: double.infinity,
                            color: Colors.white,
                          );
                        }
                      }
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
