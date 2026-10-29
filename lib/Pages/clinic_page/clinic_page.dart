import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/google_map_screen/google_map_screen.dart';
import 'package:clinic_dr_alla/model/clinic_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailsPage extends StatelessWidget {
  final ClinicModel doctor;

  const DoctorDetailsPage({Key? key, required this.doctor}) : super(key: key);

  Future<void> _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSuggestionDialog(BuildContext context) {
    TextEditingController suggestionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("اقتراح تعديل"),
        content: TextField(
          controller: suggestionController,
          maxLines: 3,
          decoration: InputDecoration(hintText: "اكتب ملاحظتك هنا"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              String suggestion = suggestionController.text.trim();
              if (suggestion.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تم إرسال اقتراحك بنجاح")),
                );
              }
            },
            child: Text("إرسال"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(doctor.id);

    return Scaffold(
      appBar: MyCustomAppBar(
        name: doctor.name,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () {
              if (isFavorite) {
                favoriteProvider.removeFavorite(doctor.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تمت إزالة العنصر من المفضلة")),
                );
              } else {
                final item = FavoriteItem(
                  productId: doctor.id,
                  name: doctor.name,
                  nameEn: doctor.name,
                  nameHe: doctor.name,
                  desc: doctor.description,
                  image: doctor.image,
                );

                favoriteProvider.addFavorite(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("تمت إضافة العنصر إلى المفضلة")),
                );
              }
            },
          ),
        ],
      ),
      body: FadeSlideIn(
          child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NetImage(
                doctor.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Text(
              doctor.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              doctor.categoryName,
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
            Divider(height: 30),
            _buildDetailRow("📍 العنوان", doctor.address),
            _buildDetailRow("🏙 المدينة", doctor.cityName),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                doctor.description,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(doctor.mobile),
                icon: Icon(Icons.phone),
                label: Text('اتصل الآن: ${doctor.mobile}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (doctor.latitude != null && doctor.longitude != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoogleMapScreen(
                              hospitalName: doctor.name,
                              lat: doctor.latitude!,
                              lng: doctor.longitude!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("الموقع غير متوفر لهذا المستشفى")),
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
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showSuggestionDialog(context),
              icon: Icon(Icons.feedback),
              label: Text("اقتراح تعديل"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 50),
          ],
        ),
      )),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: isPhone
                ? InkWell(
                    onTap: () => _makeCall(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.green[700],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
}
