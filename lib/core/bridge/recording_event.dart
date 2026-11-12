sealed class RecordingEvent {
  const RecordingEvent();

  factory RecordingEvent.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? '';
    switch (type) {
      case 'recording_started':
        return RecordingStartedEvent(
          filePath: map['filePath'] as String? ?? '',
          callerNumber: map['callerNumber'] as String? ?? 'Unknown',
          appSource: map['appSource'] as String? ?? 'Cellular',
          mediaType: map['mediaType'] as String? ?? 'audio',
        );
      case 'amplitude_update':
        final amp = (map['amplitude'] as num?)?.toDouble() ?? 0.0;
        return AmplitudeUpdateEvent(amplitude: amp);
      case 'recording_completed':
        return RecordingCompletedEvent(
          filePath: map['filePath'] as String? ?? '',
          callerNumber: map['callerNumber'] as String? ?? 'Unknown',
          appSource: map['appSource'] as String? ?? 'Cellular',
          durationSec: (map['durationSec'] as num?)?.toInt() ?? 0,
          fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
          createdAt:
              (map['createdAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
          mediaType: map['mediaType'] as String? ?? 'audio',
        );
      case 'recording_warning':
        return RecordingWarningEvent(
          messageKey: map['messageKey'] as String? ?? 'recording_warning',
        );
      default:
        return UnknownRecordingEvent(raw: map);
    }
  }
}

class RecordingStartedEvent extends RecordingEvent {
  final String filePath;
  final String callerNumber;
  final String appSource;
  final String mediaType;

  const RecordingStartedEvent({
    required this.filePath,
    required this.callerNumber,
    required this.appSource,
    this.mediaType = 'audio',
  });
}

class AmplitudeUpdateEvent extends RecordingEvent {
  final double amplitude;

  const AmplitudeUpdateEvent({required this.amplitude});
}

class RecordingCompletedEvent extends RecordingEvent {
  final String filePath;
  final String callerNumber;
  final String appSource;
  final int durationSec;
  final int fileSize;
  final int createdAt;
  final String mediaType;

  const RecordingCompletedEvent({
    required this.filePath,
    required this.callerNumber,
    required this.appSource,
    required this.durationSec,
    required this.fileSize,
    required this.createdAt,
    this.mediaType = 'audio',
  });
}

class RecordingWarningEvent extends RecordingEvent {
  final String messageKey;

  const RecordingWarningEvent({required this.messageKey});
}

class UnknownRecordingEvent extends RecordingEvent {
  final Map<dynamic, dynamic> raw;
  const UnknownRecordingEvent({required this.raw});
}
