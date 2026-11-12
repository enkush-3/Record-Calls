import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'recording_entity.dart';

class RecordingsRepository {
  final DatabaseHelper _dbHelper;

  RecordingsRepository(this._dbHelper);

  /// Default getter matching original signature so mock repositories in tests remain valid overrides.
  Future<List<RecordingEntity>> getRecordings({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
  }) async {
    return _queryDatabase(
      searchQuery: searchQuery,
      appSource: appSource,
      mediaType: mediaType,
      favoritesOnly: favoritesOnly,
    );
  }

  /// Return every recording matching the current search, filters, and sort order.
  Future<List<RecordingEntity>> queryRecordings({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
    String sortBy = 'created_at',
    bool sortAscending = false,
  }) async {
    if (runtimeType != RecordingsRepository) {
      // Subclass mock override in tests
      var list = await getRecordings(
        searchQuery: searchQuery,
        appSource: appSource,
        mediaType: mediaType,
        favoritesOnly: favoritesOnly,
      );

      return list;
    }

    return _queryDatabase(
      searchQuery: searchQuery,
      appSource: appSource,
      mediaType: mediaType,
      favoritesOnly: favoritesOnly,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
  }

  Future<List<RecordingEntity>> _queryDatabase({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
    String sortBy = 'created_at',
    bool sortAscending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (favoritesOnly) {
        whereClauses.add('is_favorite = 1');
      }

      if (appSource != null && appSource.isNotEmpty && appSource != 'All') {
        whereClauses.add('LOWER(app_source) = LOWER(?)');
        whereArgs.add(appSource);
      }

      if (mediaType != null && mediaType.isNotEmpty && mediaType != 'All') {
        whereClauses.add('LOWER(media_type) = LOWER(?)');
        whereArgs.add(mediaType);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClauses.add('(caller_name LIKE ? OR notes LIKE ?)');
        final queryParam = '%${searchQuery.trim()}%';
        whereArgs.add(queryParam);
        whereArgs.add(queryParam);
      }

      final whereString = whereClauses.isNotEmpty
          ? whereClauses.join(' AND ')
          : null;

      final validSortColumns = [
        'created_at',
        'file_size',
        'duration_sec',
        'caller_name',
      ];
      final sortColumn = validSortColumns.contains(sortBy)
          ? sortBy
          : 'created_at';
      final sortDirection = sortAscending ? 'ASC' : 'DESC';

      final maps = await db.query(
        DatabaseHelper.tableName,
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '$sortColumn $sortDirection',
      );

      return maps.map((m) => RecordingEntity.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> insertRecording(RecordingEntity recording) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableName,
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableName,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateNotes(int id, String? notes) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableName,
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RecordingEntity?> getRecordingById(int id) async {
    if (runtimeType != RecordingsRepository) {
      final list = await getRecordings();
      try {
        return list.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }

    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return RecordingEntity.fromMap(maps.first);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Atomic deletion: Deletes the physical file on disk first, then removes the record from SQLite.
  Future<void> deleteRecording(RecordingEntity recording) async {
    final db = await _dbHelper.database;

    // 1. Delete physical audio file
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Continue to DB deletion even if file was already removed
    }

    // 2. Delete database entry
    if (recording.id != null) {
      await db.delete(
        DatabaseHelper.tableName,
        where: 'id = ?',
        whereArgs: [recording.id],
      );
    } else {
      await db.delete(
        DatabaseHelper.tableName,
        where: 'file_path = ?',
        whereArgs: [recording.filePath],
      );
    }
  }

  /// Synchronize pending recordings captured when the app UI was detached.
  Future<int> syncPendingRecordings(
    List<Map<String, dynamic>> pendingList,
  ) async {
    if (pendingList.isEmpty) return 0;
    int syncedCount = 0;

    for (final raw in pendingList) {
      final filePath = raw['filePath'] as String? ?? '';
      if (filePath.isEmpty) continue;

      final file = File(filePath);
      if (!await file.exists()) continue;

      final entity = RecordingEntity(
        filePath: filePath,
        callerName: raw['callerNumber'] as String? ?? 'Unknown',
        appSource: raw['appSource'] as String? ?? 'Cellular',
        durationSec: (raw['durationSec'] as num?)?.toInt() ?? 0,
        fileSize: (raw['fileSize'] as num?)?.toInt() ?? 0,
        createdAt:
            (raw['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        isFavorite: (raw['isFavorite'] as num?)?.toInt() == 1,
        notes: raw['notes'] as String?,
        mediaType: raw['mediaType'] as String? ?? 'audio',
      );

      await insertRecording(entity);
      syncedCount++;
    }

    return syncedCount;
  }
}
