import 'dart:async';
import 'package:flutter/services.dart';
import 'permission_status_model.dart';
import 'recording_event.dart';

class NativeBridge {
  static const MethodChannel _commandChannel = MethodChannel(
    'mn.callrecorder/command',
  );
  static const EventChannel _streamChannel = EventChannel(
    'mn.callrecorder/stream',
  );

  Stream<RecordingEvent>? _cachedStream;

  Stream<RecordingEvent> get recordingStream {
    _cachedStream ??= _streamChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      if (event is Map) {
        return RecordingEvent.fromMap(event);
      }
      return UnknownRecordingEvent(raw: {'value': event});
    });
    return _cachedStream!;
  }

  Future<PermissionStatusModel> getPermissionsStatus() async {
    try {
      final result = await _commandChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getPermissionsStatus',
      );
      return PermissionStatusModel.fromMap(result);
    } catch (_) {
      return PermissionStatusModel.initial();
    }
  }

  Future<bool> openAccessibilitySettings() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'openAccessibilitySettings',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppDetailsSettings() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'openAppDetailsSettings',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAutoRecordEnabled(bool enabled) async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'setAutoRecordEnabled',
        {'enabled': enabled},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAutoRecordEnabled() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'isAutoRecordEnabled',
      );
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<String> getStorageDirectory() async {
    try {
      final res = await _commandChannel.invokeMethod<String>(
        'getStorageDirectory',
      );
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> setStorageDirectory(String path) async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'setStorageDirectory',
        {'path': path},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> resetStorageDirectory() async {
    try {
      final res = await _commandChannel.invokeMethod<String>(
        'resetStorageDirectory',
      );
      return res ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<List<Map<String, String>>> getAvailableStorageDirectories() async {
    try {
      final List<dynamic>? list = await _commandChannel
          .invokeMethod<List<dynamic>>('getAvailableStorageDirectories');
      if (list == null) return [];
      return list.map((item) {
        if (item is Map) {
          return item.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        return <String, String>{};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStorageDirectoryInfo() async {
    try {
      final res = await _commandChannel.invokeMapMethod<String, dynamic>(
        'getStorageDirectoryInfo',
      );
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<bool> startManualRecording({String? audioSource}) async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'startManualRecording',
        {'audioSource': audioSource},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopManualRecording() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'stopManualRecording',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startVideoRecording({
    String callerNumber = 'Manual Video Test',
    String appSource = 'Manual',
    String audioSource = 'mic_only',
  }) async {
    try {
      final res = await _commandChannel
          .invokeMethod<bool>('startVideoRecording', {
            'callerNumber': callerNumber,
            'appSource': appSource,
            'audioSource': audioSource,
          });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopVideoRecording() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'stopVideoRecording',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isVideoRecording() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>('isVideoRecording');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isRecording() async {
    try {
      final res = await _commandChannel.invokeMethod<bool>('isRecording');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingRecordings() async {
    try {
      final List<dynamic>? rawList = await _commandChannel
          .invokeMethod<List<dynamic>>('fetchPendingRecordings');
      if (rawList == null) return [];
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> setAudioRecordingSource(String source) async {
    try {
      final res = await _commandChannel.invokeMethod<bool>(
        'setAudioRecordingSource',
        {'source': source},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> getAudioRecordingSource() async {
    try {
      final res = await _commandChannel.invokeMethod<String>(
        'getAudioRecordingSource',
      );
      return res ?? 'both';
    } catch (_) {
      return 'both';
    }
  }
}
