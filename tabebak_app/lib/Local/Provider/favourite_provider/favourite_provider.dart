import 'package:clinic_dr_alla/Local/Database/database.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  List<FavoriteItem> _favorites = [];

  List<FavoriteItem> get favorites => _favorites;

  Future<void> loadFavorites() async {
    _favorites = await CartDatabaseHelper().getFavoriteItems();
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return _favorites.any((item) => item.productId == productId);
  }

  Future<void> addFavorite(FavoriteItem item) async {
    await CartDatabaseHelper().insertFavoriteItem(item);
    await loadFavorites();
  }

  Future<void> removeFavorite(int productId) async {
    await CartDatabaseHelper().deleteFavoriteItem(productId);
    await loadFavorites();
  }
}
