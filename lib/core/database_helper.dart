import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cbt_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Buat tabel sederhana untuk menyimpan JSON
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_cache (
        id TEXT PRIMARY KEY,
        json_data TEXT,
        updated_at TEXT
      )
    ''');
  }

  // Menyimpan data dari server ke HP (Otomatis menimpa yang lama)
  Future<void> saveCache(String id, String jsonData) async {
    final db = await instance.database;
    await db.insert('offline_cache', {
      'id': id,
      'json_data': jsonData,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Mengambil data dari HP
  Future<String?> getCache(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'offline_cache',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first['json_data'] as String;
    }
    return null;
  }
}
