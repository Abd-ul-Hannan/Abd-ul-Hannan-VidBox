import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/download_model.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vidbox.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            id TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            thumbnail TEXT,
            type TEXT NOT NULL,
            quality TEXT NOT NULL,
            status TEXT NOT NULL,
            progress INTEGER DEFAULT 0,
            file_path TEXT,
            platform TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> saveDownload(DownloadModel download) async {
    try {
      final db = await database;
      await db.insert(
        'downloads',
        download.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving download: $e');
      rethrow;
    }
  }

  static Future<List<DownloadModel>> getDownloadHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'downloads',
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => DownloadModel.fromJson(map)).toList();
    } catch (e) {
      print('Error getting download history: $e');
      return [];
    }
  }

  static Future<DownloadModel?> findDownloadByUrl(String url) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'downloads',
        where: 'url = ?',
        whereArgs: [url],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return DownloadModel.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      print('Error finding download: $e');
      return null;
    }
  }

  static Future<void> updateDownloadStatus({
    required String id,
    required String status,
    int? progress,
    String? filePath,
  }) async {
    try {
      final db = await database;
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (progress != null) {
        updates['progress'] = progress;
      }

      if (filePath != null) {
        updates['file_path'] = filePath;
      }

      await db.update(
        'downloads',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating download status: $e');
    }
  }

  static Future<void> deleteDownload(String id) async {
    try {
      final db = await database;
      await db.delete(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting download: $e');
    }
  }

  static Future<void> clearDownloadHistory() async {
    try {
      final db = await database;
      await db.delete('downloads');
    } catch (e) {
      print('Error clearing download history: $e');
    }
  }
}
