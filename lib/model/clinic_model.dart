class ClinicModel {
  final int id;
  final String image;
  final String name;
  final String description;
  final String mobile;
  final String address;
  final String cityName;
  final String categoryName;
  final double? latitude;
  final double? longitude;

  ClinicModel({
    required this.id,
    required this.image,
    required this.name,
    required this.description,
    required this.mobile,
    required this.address,
    required this.cityName,
    required this.categoryName,
    this.latitude,
    this.longitude,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      description: json['description'],
      mobile: json['mobile'],
      address: json['address'],
      cityName: json['city']?['name'] ?? '',
      categoryName: json['category']?['name'] ?? '',
      latitude: double.tryParse(json['coordinates']?[0]?['lat'] ?? ''),
      longitude: double.tryParse(json['coordinates']?[0]?['lng'] ?? ''),
    );
  }
}
