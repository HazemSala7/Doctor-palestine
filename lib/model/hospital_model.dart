class HospitalModel {
  final int id;
  final String name;
  final String coverImage;
  final String logoImage;
  final String address;
  final String description;
  final String mobile;
  final int experiance;
  final String cityName;
  final double? latitude;
  final double? longitude;

  HospitalModel({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.logoImage,
    required this.address,
    required this.description,
    required this.mobile,
    required this.experiance,
    required this.cityName,
    this.latitude,
    this.longitude,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'],
      name: json['name'],
      coverImage: json['cover_image'],
      logoImage: json['logo_image'],
      address: json['address'],
      description: json['description'],
      mobile: json['mobile'],
      experiance: json['experiance'],
      cityName: json['city']?['name'] ?? '',
      latitude: double.tryParse(json['coordinates']?[0]?['lat'] ?? ''),
      longitude: double.tryParse(json['coordinates']?[0]?['lng'] ?? ''),
    );
  }
}
