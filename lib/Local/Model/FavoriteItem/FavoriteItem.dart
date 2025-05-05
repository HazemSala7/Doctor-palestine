class FavoriteItem {
  final int? id;
  final int productId; // Unique identifier for the product
  final String name;
  final String name_en;
  final String name_he;
  final String image;
  final String discount;
  final String desc;
  final String category_id;
  final double price;

  FavoriteItem({
    this.id,
    required this.productId,
    required this.name,
    required this.name_he,
    required this.name_en,
    required this.image,
    required this.discount,
    required this.desc,
    required this.category_id,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'name_en': name_en,
      'name_he': name_he,
      'image': image,
      'discount': discount,
      'desc': desc,
      'category_id': category_id,
      'price': price,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'],
      productId: json['productId'],
      name: json['name'],
      name_he: json['name_he'],
      name_en: json['name_en'],
      image: json['image'],
      discount: json['discount'],
      desc: json['desc'],
      category_id: json['category_id'],
      price: json['price'],
    );
  }

  FavoriteItem copyWith({
    int? id,
    int? productId,
    String? name,
    String? name_en,
    String? name_he,
    String? image,
    String? discount,
    String? category_id,
    String? desc,
    double? price,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      name_en: name_en ?? this.name_en,
      name_he: name_he ?? this.name_he,
      desc: desc ?? this.desc,
      category_id: category_id ?? this.category_id,
      price: price ?? this.price,
      image: image ?? this.image,
      discount: discount ?? this.discount,
    );
  }
}
