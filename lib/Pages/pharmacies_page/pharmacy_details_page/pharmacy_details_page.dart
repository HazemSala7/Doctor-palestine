import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Pages/google_map_screen/google_map_screen.dart';
import 'package:clinic_dr_alla/model/pharmacy_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyDetailsPage extends StatelessWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailsPage({Key? key, required this.pharmacy})
      : super(key: key);

  Future<void> _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not call $phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyCustomAppBar(name: pharmacy.name),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Image.network(
              pharmacy.coverImage,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),

            // Logo + Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      pharmacy.logoImage,
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
                          pharmacy.name,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text("📍 ${pharmacy.address}"),
                        Text("🏙 المدينة: ${pharmacy.cityName}"),
                        Text("💼 الخبرة: ${pharmacy.experiance} سنة"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                pharmacy.description,
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
                          onPressed: () => _makeCall(pharmacy.mobile),
                          icon: Icon(Icons.phone),
                          label: Text('اتصل الآن: ${pharmacy.mobile}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                            if (pharmacy.latitude != null &&
                                pharmacy.longitude != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoogleMapScreen(
                                    hospitalName: pharmacy.name,
                                    lat: pharmacy.latitude!,
                                    lng: pharmacy.longitude!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("الموقع غير متوفر لهذا المستشفى")),
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
                                borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}
