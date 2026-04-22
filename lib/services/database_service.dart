import 'package:gps_camera/models/geo_photo.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  static const String _dbName = 'gps_camera.db';
  static const int _dbVersion = 1;
  static const String _table = 'geo_photos';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final String dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
CREATE TABLE $_table (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  image_path  TEXT    NOT NULL,
  thumb_path  TEXT,
  latitude    REAL    NOT NULL,
  longitude   REAL    NOT NULL,
  altitude    REAL,
  accuracy    REAL,
  heading     REAL,
  speed       REAL,
  address     TEXT,
  city        TEXT,
  country     TEXT,
  caption     TEXT,
  timestamp   TEXT    NOT NULL,
  trip_id     INTEGER,
  is_synced   INTEGER DEFAULT 0,
  created_at  TEXT    NOT NULL
)
''');
      },
    );
  }

  Future<int> insert(GeoPhoto photo) async {
    final Database db = await database;
    final Map<String, dynamic> payload = photo.toMap()..remove('id');
    return db.insert(_table, payload);
  }

  Future<List<GeoPhoto>> getAll() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      orderBy: 'timestamp DESC',
    );
    return rows.map(GeoPhoto.fromMap).toList(growable: false);
  }

  Future<GeoPhoto?> getById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GeoPhoto.fromMap(rows.first);
  }

  Future<void> update(GeoPhoto photo) async {
    if (photo.id == null) {
      throw ArgumentError('Cannot update a GeoPhoto without an id.');
    }

    final Database db = await database;
    final Map<String, dynamic> payload = photo.toMap()..remove('id');
    await db.update(
      _table,
      payload,
      where: 'id = ?',
      whereArgs: <Object?>[photo.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<GeoPhoto>> search(String query) async {
    final Database db = await database;
    final String q = '%${query.trim()}%';
    final List<Map<String, dynamic>> rows = await db.query(
      _table,
      where: 'address LIKE ? OR city LIKE ?',
      whereArgs: <Object?>[q, q],
      orderBy: 'timestamp DESC',
    );
    return rows.map(GeoPhoto.fromMap).toList(growable: false);
  }
}
