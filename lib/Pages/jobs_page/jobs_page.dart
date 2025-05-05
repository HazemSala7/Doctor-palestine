import 'dart:convert';
import 'package:clinic_dr_alla/Components/custom_app_bar/custom_app_bar.dart';
import 'package:clinic_dr_alla/model/job_model.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JobsPage extends StatefulWidget {
  @override
  _JobsPageState createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final ScrollController _scrollController = ScrollController();
  List<JobModel> _pharmacies = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _jobs = [];
  int? _selectedCityId;

  Future<void> fetchCities() async {
    try {
      final response =
          await http.get(Uri.parse('$urlFilters'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _jobs = [
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
    fetchJobs();
    fetchCities();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _currentPage <= _lastPage) {
        fetchJobs();
      }
    });
  }

  Future<void> fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      String query = '?page=$_currentPage';
      if (_selectedCityId != null) query += '&city_id=$_selectedCityId';

      final response = await http.get(Uri.parse('$urlJobs$query'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> pageData = jsonDecode(response.body);

        final List<dynamic> data = pageData['data'];

        final List<JobModel> fetched =
            data.map((e) => JobModel.fromJson(e)).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyCustomAppBar(name: "الوظائف"),
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
                    items: _jobs.map((c) {
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
                      fetchJobs();
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _pharmacies.length,
                    itemBuilder: (context, index) {
                      final job = _pharmacies[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (job.city?.image != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    job.city!.image,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              SizedBox(height: 10),
                              Text(
                                job.title,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'نوع الوظيفة: ${job.type.replaceAll('-', ' ')}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              Text(
                                'الموقع: ${job.location}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              if (job.city != null)
                                Text(
                                  'المدينة: ${job.city!.name}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              SizedBox(height: 8),
                              Text(
                                job.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
