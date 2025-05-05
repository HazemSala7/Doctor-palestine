import 'dart:convert';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/Pages/laboratories_page/laboratory_details_page/laboratory_details_page.dart';
import 'package:clinic_dr_alla/model/laboratory_model.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LaboratoriesPage extends StatefulWidget {
  @override
  _LaboratoriesPageState createState() => _LaboratoriesPageState();
}

class _LaboratoriesPageState extends State<LaboratoriesPage> {
  final ScrollController _scrollController = ScrollController();
  List<LaboratoryModel> _pharmacies = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _cities = [];
  int? _selectedCityId;

  Future<void> fetchCities() async {
    try {
      final response =
          await http.get(Uri.parse('$urlFilters'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _cities = [
            {'id': null, 'name': 'الكل'},
            ...List<Map<String, dynamic>>.from(json['cities'])
          ];
        });
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLaboratories();
    fetchCities();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _currentPage <= _lastPage) {
        fetchLaboratories();
      }
    });
  }

  Future<void> fetchLaboratories() async {
    setState(() => _isLoading = true);
    try {
      String query = '?page=$_currentPage';
      if (_selectedCityId != null) query += '&city_id=$_selectedCityId';

      final response = await http.get(Uri.parse('$urlLaboratories$query'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> pageData = jsonDecode(response.body);

        final List<dynamic> data = pageData['data'];
        final List<LaboratoryModel> fetched =
            data.map((e) => LaboratoryModel.fromJson(e)).toList();

        setState(() {
          _pharmacies.addAll(fetched);
          _currentPage = pageData['current_page'] + 1;
          _lastPage = pageData['last_page'];
        });
      }
    } catch (e) {
      print('Error fetching pharmacies: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _callPharmacy(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyCustomAppBar(name: "مختبرات طبية"),
      body: _pharmacies.isEmpty && _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    value: _selectedCityId,
                    hint: Text("اختر المدينة"),
                    items: _cities.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCityId = val;
                        _currentPage = 1;
                        _pharmacies.clear();
                      });
                      fetchLaboratories();
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(12),
                    itemCount: _pharmacies.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _pharmacies.length) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final pharmacy = _pharmacies[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LaboratoryDetailsPage(laboratory: pharmacy),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: Image.network(pharmacy.coverImage,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        pharmacy.logoImage,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pharmacy.name,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 4),
                                          Text(pharmacy.address,
                                              style: TextStyle(
                                                  color: Colors.grey[600])),
                                          SizedBox(height: 4),
                                          Text("المدينة: ${pharmacy.cityName}"),
                                          Text(
                                              "الخبرة: ${pharmacy.experiance} سنة"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  pharmacy.description,
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.phone),
                                    label:
                                        Text('اتصل الآن: ${pharmacy.mobile}'),
                                    onPressed: () =>
                                        _callPharmacy(pharmacy.mobile),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                )
              ],
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
