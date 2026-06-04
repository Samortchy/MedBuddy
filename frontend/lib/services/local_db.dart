import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local SQFLite database. Currently stores profile images on-device
/// (create / read / update / delete) keyed by the user's id.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'medbuddy.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profile_images (
            user_id    TEXT PRIMARY KEY,
            image      BLOB NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // ── Profile images CRUD ──────────────────────────────────────────────────

  Future<void> saveProfileImage(String userId, Uint8List bytes) async {
    final db = await _database;
    await db.insert(
      'profile_images',
      {
        'user_id': userId,
        'image': bytes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // create or update
    );
  }

  Future<Uint8List?> getProfileImage(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'profile_images',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final blob = rows.first['image'];
    if (blob is Uint8List) return blob;
    if (blob is List<int>) return Uint8List.fromList(blob);
    return null;
  }

  Future<void> deleteProfileImage(String userId) async {
    final db = await _database;
    await db.delete('profile_images', where: 'user_id = ?', whereArgs: [userId]);
  }
}
