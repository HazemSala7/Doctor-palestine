import 'dart:convert';
import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:clinic_dr_alla/Pages/clinic_page/clinic_page.dart';
import 'package:clinic_dr_alla/model/clinic_model.dart';
import 'package:clinic_dr_alla/model/paginated_clinics_response.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ClinicsHomePage extends StatefulWidget {
  final int? initialCityId;
  final int? initialCategoryId;
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  final String languageCode;

  const ClinicsHomePage(
      {this.initialCityId,
      this.initialCategoryId,
      required this.changeTabIndex,
      required this.onLanguageSelected,
      required this.languageCode});

  @override
  _ClinicsHomePageState createState() => _ClinicsHomePageState();
}

class _ClinicsHomePageState extends State<ClinicsHomePage> {
  final ScrollController _scrollController = ScrollController();
  List<ClinicModel> _clinics = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cities = [];
  int? _selectedCategoryId;
  int? _selectedCityId;
  final TextEditingController _searchController = TextEditingController();
  String? _searchKey;

  Future<void> fetchFilters() async {
    try {
      final response =
          await http.get(Uri.parse('$urlFilters'), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        setState(() {
          _categories = [
            {'id': null, 'name': 'الكل'},
            ...List<Map<String, dynamic>>.from(json['categories'])
          ];
          _cities = [
            {'id': null, 'name': 'الكل'},
            ...List<Map<String, dynamic>>.from(json['cities'])
          ];
        });
      }
    } catch (e) {
      print('Error fetching filters: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Assign initial filter values
    _selectedCityId = widget.initialCityId;
    _selectedCategoryId = widget.initialCategoryId;

    fetchFilters();
    fetchClinics();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _currentPage < _lastPage) {
        fetchClinics();
      }
    });
  }

  Future<void> fetchClinics({bool reset = false}) async {
    if (reset) {
      _clinics.clear();
      _currentPage = 1;
      _lastPage = 1;
    }

    setState(() => _isLoading = true);
    try {
      String query = '?page=$_currentPage';
      if (_selectedCategoryId != null)
        query += '&category_id=$_selectedCategoryId';
      if (_selectedCityId != null) query += '&city_id=$_selectedCityId';
      if (_searchKey != null && _searchKey!.isNotEmpty)
        query += '&key=${Uri.encodeComponent(_searchKey!)}';

      final response =
          await http.get(Uri.parse('$urlDoctors$query'), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        final paginated = PaginatedClinicsResponse.fromJson(json);
        setState(() {
          _clinics.addAll(paginated.clinics);
          _currentPage = paginated.currentPage + 1;
          _lastPage = paginated.lastPage;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('العيادات / الأطباء')),
      body: _clinics.isEmpty && _isLoading
          ? Center(child: SpinKitPulse(color: kMainColor, size: 60))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) {
                      setState(() {
                        _searchKey = value;
                      });
                      fetchClinics(reset: true);
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم الطبيب أو العيادة',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchKey = null;
                                });
                                fetchClinics(reset: true);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                          child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        value: _selectedCategoryId,
                        hint: Text("اختر التخصص"),
                        items: _categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                          fetchClinics(reset: true);
                        },
                      )),
                      SizedBox(width: 10),
                      // City Dropdown
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          isExpanded: true,
                          value: _selectedCityId,
                          hint: Text("اختر المدينة"),
                          items: _cities.map((c) {
                            return DropdownMenuItem<int>(
                              value: c['id'],
                              child: Text(c['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCityId = val);
                            fetchClinics(reset: true);
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(12),
                    itemCount: _clinics.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _clinics.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final clinic = _clinics[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorDetailsPage(doctor: clinic),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Card(
                            margin: EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      clinic.image,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(clinic.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text(clinic.address,
                                            style: TextStyle(
                                                color: Colors.grey[600])),
                                        SizedBox(height: 4),
                                        Text("🏙 المدينة: ${clinic.cityName}"),
                                        Text(
                                            "🩺 التخصص: ${clinic.categoryName}"),
                                        SizedBox(height: 6),
                                        Text(
                                          clinic.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        SizedBox(height: 6),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final phoneUri = Uri.parse(
                                                "tel:${clinic.mobile}");
                                            if (await canLaunchUrl(phoneUri)) {
                                              await launchUrl(phoneUri);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        "لا يمكن إجراء المكالمة")),
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.phone),
                                          label: Text(
                                              'اتصل الآن: ${clinic.mobile}'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
