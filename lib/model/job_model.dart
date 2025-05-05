class JobModel {
  final int id;
  final String title;
  final String type;
  final String location;
  final String description;
  final CityModel? city;

  JobModel({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.description,
    required this.city,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      location: json['location'],
      description: json['description'],
      city: json['city'] != null ? CityModel.fromJson(json['city']) : null,
    );
  }
}

class CityModel {
  final int id;
  final String name;
  final String image;

  CityModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}
