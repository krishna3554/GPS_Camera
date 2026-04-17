import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/geo_photo.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _dbName = 'gps_camera.db';
  static const _table = 'geo_photos';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            address TEXT,
            altitude REAL,
            accuracy REAL
          )
        ''');
      },
    );
  }

  Future<int> insertPhoto(GeoPhoto photo) async {
    return _db!.insert(_table, photo.toMap()..remove('id'));
  }

  Future<List<GeoPhoto>> getAllPhotos() async {
    final rows = await _db!.query(_table, orderBy: 'id DESC');
    return rows.map(GeoPhoto.fromMap).toList();
  }

  Future<void> deletePhoto(int id) async {
    await _db!.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
