import 'clinic_model.dart';

class PaginatedClinicsResponse {
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final List<ClinicModel> clinics;

  PaginatedClinicsResponse({
    required this.currentPage,
    required this.lastPage,
    required this.nextPageUrl,
    required this.clinics,
  });

  factory PaginatedClinicsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedClinicsResponse(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      nextPageUrl: json['next_page_url'],
      clinics: List<ClinicModel>.from(
          json['data'].map((c) => ClinicModel.fromJson(c))),
    );
  }
}
