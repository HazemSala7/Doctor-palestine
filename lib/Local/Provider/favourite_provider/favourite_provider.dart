import 'package:clinic_dr_alla/Local/Database/database.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:flutter/material.dart';

class FavouriteProvider extends ChangeNotifier {
  List<FavoriteItem> _favouritesItems = [];
  CartDatabaseHelper _dbHelper = CartDatabaseHelper();

  List<FavoriteItem> get favoriteItems => _favouritesItems;
  int get favouriteItemsCount => _favouritesItems.length;

  FavouriteProvider() {
    _init();
  }

  Future<void> _init() async {
    _favouritesItems = await _dbHelper.getFavoriteItems();
    notifyListeners();
  }

  Future<void> addToFavorite(FavoriteItem item) async {
    // Item does not exist in the cart, add it as a new item
    await _dbHelper.insertFavoriteItem(item);
    _favouritesItems.add(item);
    // Refresh _cartItems with the latest data from the database
    _favouritesItems = await _dbHelper.getFavoriteItems();

    notifyListeners();
  }

  bool isProductFavorite(int productId) {
    // Assuming you have a list of favorite items in _favoriteItems
    return _favouritesItems.any((item) => item.productId == productId);
  }

  Future<void> removeFromFavorite(int productId) async {
    await _dbHelper.deleteFavoriteItem(productId);
    _favouritesItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  Future<FavoriteItem?> getFavoriteItemByProductId(int productId) async {
    return await CartDatabaseHelper().getFavoriteItemByProductId(productId);
  }

  List<Map<String, dynamic>> getProductsArray() {
    List<Map<String, dynamic>> productsArray = [];

    for (FavoriteItem item in _favouritesItems) {
      Map<String, dynamic> productData = {
        'product_id': item.productId,
        'name': item.name,
        'name_en': item.name_en,
        'name_he': item.name_he,
        'image': item.image,
        'category_id': item.category_id,
        'desc': item.desc,
        'price': item.price,
        'discount': item.discount,
      };
      productsArray.add(productData);
    }

    return productsArray;
  }
}
