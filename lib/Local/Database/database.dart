import 'dart:async';
import 'dart:io';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class CartDatabaseHelper {
  static final CartDatabaseHelper _instance = CartDatabaseHelper._internal();
  static final int dbVersion = 15;

  factory CartDatabaseHelper() => _instance;

  CartDatabaseHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'cart.db');

    return await openDatabase(
      path,
      version: dbVersion,
      onUpgrade: _onUpgrade,
      onCreate: (db, version) async {
        await _createDb(db);
      },
    );
  }

  Future<void> _createDb(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        name_en TEXT NOT NULL,
        name_he TEXT NOT NULL,
        desc TEXT NOT NULL,
        category_id TEXT NOT NULL,
        image TEXT NOT NULL,
        discount TEXT NOT NULL,
        price REAL NOT NULL,
        color TEXT DEFAULT '',
        size TEXT DEFAULT ''
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop existing tables
    await db.execute('DROP TABLE IF EXISTS cart');
    await db.execute('DROP TABLE IF EXISTS favorites');

    // Recreate tables with updated schema
    await _createDb(db);
  }

  Future<FavoriteItem?> getFavoriteItemByProductId(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'favorites',
      where: 'productId = ?',
      whereArgs: [productId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return FavoriteItem.fromJson(maps.first);
  }

  Future<int> insertFavoriteItem(FavoriteItem item) async {
    final db = await database;
    return await db!.insert('favorites', item.toJson());
  }

  Future<List<FavoriteItem>> getFavoriteItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('favorites');
    return List.generate(
      maps.length,
      (i) => FavoriteItem.fromJson(maps[i]),
    );
  }

  Future<void> deleteFavoriteItem(int id) async {
    final db = await database;
    await db!.delete('favorites', where: 'productId = ?', whereArgs: [id]);
  }
}
