class CityModel {
  final int id;
  final String name;
  final String image;

  CityModel({required this.id, required this.name, required this.image});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}
