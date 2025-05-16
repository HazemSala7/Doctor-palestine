class FavoriteItem {
  final int productId;
  final String name;
  final String nameEn;
  final String nameHe;
  final String desc;
  final String image;
  final String color;
  final String size;

  FavoriteItem({
    required this.productId,
    required this.name,
    required this.nameEn,
    required this.nameHe,
    required this.desc,
    required this.image,
    this.color = '',
    this.size = '',
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      productId: json['productId'],
      name: json['name'],
      nameEn: json['name_en'],
      nameHe: json['name_he'],
      desc: json['desc'],
      image: json['image'],
      color: json['color'] ?? '',
      size: json['size'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'name_en': nameEn,
      'name_he': nameHe,
      'desc': desc,
      'image': image,
      'color': color,
      'size': size,
    };
  }
}
