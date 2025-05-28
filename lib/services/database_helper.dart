import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'markers.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE markers(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL,
            synced INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertMarker(Map<String, dynamic> marker) async {
    final db = await database;
    await db.insert('markers', marker, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMarkers() async {
    final db = await database;
    return await db.query('markers', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> updateMarkerSyncStatus(String id) async {
    final db = await database;
    await db.update('markers', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
