import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SearchHistoryItem {
  final int? id;
  final String address;
  final double latitude;
  final double longitude;
  final int timestamp;

  SearchHistoryItem({
    this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      id: map['id'] as int?,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: map['timestamp'] as int,
    );
  }
}

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    final pathString = join(await getDatabasesPath(), 'search_history.db');
    return await openDatabase(
      pathString,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            address TEXT UNIQUE,
            latitude REAL,
            longitude REAL,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> insertSearch(String address, double lat, double lng) async {
    final db = await database;
    await db.insert(
      'search_history',
      {
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SearchHistoryItem>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      orderBy: 'timestamp DESC',
      limit: 10,
    );
    return maps.map((m) => SearchHistoryItem.fromMap(m)).toList();
  }

  static Future<void> clearHistory() async {
    final db = await database;
    await db.delete('search_history');
  }
}
