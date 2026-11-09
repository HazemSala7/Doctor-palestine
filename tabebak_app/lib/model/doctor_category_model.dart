class DoctorCategoryModel {
  final int id;
  final String name;
  final String image;

  DoctorCategoryModel(
      {required this.id, required this.name, required this.image});

  factory DoctorCategoryModel.fromJson(Map<String, dynamic> json) {
    return DoctorCategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}
