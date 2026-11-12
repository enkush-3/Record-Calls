import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'record_calls.db';
  static const int _dbVersion = 4;
  static const String tableName = 'recordings';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT NOT NULL UNIQUE,
            caller_name TEXT NOT NULL,
            app_source TEXT NOT NULL,
            duration_sec INTEGER NOT NULL,
            file_size INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            media_type TEXT NOT NULL DEFAULT 'audio'
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_recordings_created_at ON $tableName (created_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_recordings_app_source ON $tableName (app_source)',
        );
        await db.execute(
          'CREATE INDEX idx_recordings_media_type ON $tableName (media_type)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $tableName ADD COLUMN media_type TEXT NOT NULL DEFAULT 'audio'",
          );
          await db.execute(
            'CREATE INDEX idx_recordings_media_type ON $tableName (media_type)',
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE recordings_local_only (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              file_path TEXT NOT NULL UNIQUE,
              caller_name TEXT NOT NULL,
              app_source TEXT NOT NULL,
              duration_sec INTEGER NOT NULL,
              file_size INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              is_favorite INTEGER NOT NULL DEFAULT 0,
              notes TEXT,
              media_type TEXT NOT NULL DEFAULT 'audio'
            )
          ''');
          await db.execute('''
            INSERT INTO recordings_local_only (
              id, file_path, caller_name, app_source, duration_sec, file_size,
              created_at, is_favorite, notes, media_type
            )
            SELECT id, file_path, caller_name, app_source, duration_sec, file_size,
              created_at, is_favorite, notes, media_type
            FROM $tableName
          ''');
          await db.execute('DROP TABLE $tableName');
          await db.execute(
            'ALTER TABLE recordings_local_only RENAME TO $tableName',
          );
          await db.execute(
            'CREATE INDEX idx_recordings_created_at ON $tableName (created_at DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_recordings_app_source ON $tableName (app_source)',
          );
          await db.execute(
            'CREATE INDEX idx_recordings_media_type ON $tableName (media_type)',
          );
        }
      },
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
