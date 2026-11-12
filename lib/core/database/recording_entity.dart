class RecordingEntity {
  final int? id;
  final String filePath;
  final String callerName;
  final String appSource;
  final int durationSec;
  final int fileSize;
  final int createdAt;
  final bool isFavorite;
  final String? notes;
  final String mediaType; // 'audio' or 'video'

  const RecordingEntity({
    this.id,
    required this.filePath,
    required this.callerName,
    required this.appSource,
    required this.durationSec,
    required this.fileSize,
    required this.createdAt,
    this.isFavorite = false,
    this.notes,
    this.mediaType = 'audio',
  });

  factory RecordingEntity.fromMap(Map<String, dynamic> map) {
    final fav =
        map['is_favorite'] == true ||
        (map['is_favorite'] as num?)?.toInt() == 1;
    return RecordingEntity(
      id: (map['id'] as num?)?.toInt(),
      filePath: map['file_path'] as String? ?? '',
      callerName: map['caller_name'] as String? ?? 'Unknown',
      appSource: map['app_source'] as String? ?? 'Cellular',
      durationSec: (map['duration_sec'] as num?)?.toInt() ?? 0,
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      createdAt:
          (map['created_at'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      isFavorite: fav,
      notes: map['notes'] as String?,
      mediaType: map['media_type'] as String? ?? 'audio',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_path': filePath,
      'caller_name': callerName,
      'app_source': appSource,
      'duration_sec': durationSec,
      'file_size': fileSize,
      'created_at': createdAt,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
      'media_type': mediaType,
    };
  }

  RecordingEntity copyWith({
    int? id,
    String? filePath,
    String? callerName,
    String? appSource,
    int? durationSec,
    int? fileSize,
    int? createdAt,
    bool? isFavorite,
    String? notes,
    String? mediaType,
  }) {
    return RecordingEntity(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      callerName: callerName ?? this.callerName,
      appSource: appSource ?? this.appSource,
      durationSec: durationSec ?? this.durationSec,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}
