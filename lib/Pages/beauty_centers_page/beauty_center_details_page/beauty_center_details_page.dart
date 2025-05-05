import 'package:clinic_dr_alla/Pages/google_map_screen/google_map_screen.dart';
import 'package:clinic_dr_alla/model/beauty_center_model.dart';
import 'package:clinic_dr_alla/model/hospital_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BeautyCenterDetailsPage extends StatelessWidget {
  final BeautyCenterModel beautyCenter;

  const BeautyCenterDetailsPage({Key? key, required this.beautyCenter})
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
      appBar: AppBar(title: Text(beautyCenter.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Image.network(
              beautyCenter.coverImage,
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
                      beautyCenter.logoImage,
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
                          beautyCenter.name,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text("📍 ${beautyCenter.address}"),
                        Text("🏙 المدينة: ${beautyCenter.cityName}"),
                        Text("💼 الخبرة: ${beautyCenter.experiance} سنة"),
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
                beautyCenter.description,
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
                          onPressed: () => _makeCall(beautyCenter.mobile),
                          icon: Icon(Icons.phone),
                          label: Text('اتصل الآن: ${beautyCenter.mobile}'),
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
                            if (beautyCenter.latitude != null &&
                                beautyCenter.longitude != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoogleMapScreen(
                                    hospitalName: beautyCenter.name,
                                    lat: beautyCenter.latitude!,
                                    lng: beautyCenter.longitude!,
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
