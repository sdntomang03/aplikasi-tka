import 'dart:io';
import 'package:flutter/services.dart';
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

    // BARIS INI ADALAH KUNCINYA:
    // Hapus database lama secara paksa setiap kali aplikasi dibuka
    await deleteDatabase(path);

    print("ℹ️ Menyalin database baru dari assets...");
    try {
      await Directory(dirname(path)).create(recursive: true);
      ByteData data = await rootBundle.load(join('assets', filePath));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ DATABASE BARU DARI ASSETS BERHASIL DITIMPA!");
    } catch (e) {
      print("❌ Error menyalin database: $e");
    }

    return await openDatabase(path, version: 1);
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
