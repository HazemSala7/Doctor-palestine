import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/google_map_screen/google_map_screen.dart';
import 'package:clinic_dr_alla/model/medical_treatment_center_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalTreatmentCenterDetailsPage extends StatelessWidget {
  final MedicalTreatmentCenterModel medicalTreatmentCenter;

  const MedicalTreatmentCenterDetailsPage({
    Key? key,
    required this.medicalTreatmentCenter,
  }) : super(key: key);

  Future<void> _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'تعذر الاتصال بـ $phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(medicalTreatmentCenter.id);

    return Scaffold(
      appBar: MyCustomAppBar(
        name: medicalTreatmentCenter.name,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () {
              if (isFavorite) {
                favoriteProvider.removeFavorite(medicalTreatmentCenter.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تمت إزالة المركز من المفضلة")),
                );
              } else {
                final item = FavoriteItem(
                  productId: medicalTreatmentCenter.id,
                  name: medicalTreatmentCenter.name,
                  nameEn: medicalTreatmentCenter.name,
                  nameHe: medicalTreatmentCenter.name,
                  desc: medicalTreatmentCenter.description,
                  image: medicalTreatmentCenter.coverImage,
                );
                favoriteProvider.addFavorite(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تمت إضافة المركز إلى المفضلة")),
                );
              }
            },
          ),
        ],
      ),
      body: FadeSlideIn(
          child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NetImage(
              medicalTreatmentCenter.coverImage,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: NetImage(
                      medicalTreatmentCenter.logoImage,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicalTreatmentCenter.name,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text("📍 ${medicalTreatmentCenter.address}"),
                        Text("🏙 المدينة: ${medicalTreatmentCenter.cityName}"),
                        Text(
                            "💼 الخبرة: ${medicalTreatmentCenter.experiance} سنة"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                medicalTreatmentCenter.description,
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _makeCall(medicalTreatmentCenter.mobile),
                          icon: Icon(Icons.phone),
                          label: Text(
                              'اتصل الآن: ${medicalTreatmentCenter.mobile}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (medicalTreatmentCenter.latitude != null &&
                                medicalTreatmentCenter.longitude != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoogleMapScreen(
                                    hospitalName: medicalTreatmentCenter.name,
                                    lat: medicalTreatmentCenter.latitude!,
                                    lng: medicalTreatmentCenter.longitude!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("الموقع غير متوفر لهذا المركز"),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.map),
                          label: Text('عرض على الخريطة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      )),
    );
  }
}
