import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/bridge/native_bridge.dart';
import '../../../core/bridge/recording_event.dart';

class LiveRecordingState {
  final bool isRecording;
  final String callerNumber;
  final String appSource;
  final double amplitude;
  final int elapsedSeconds;
  final String mediaType;
  final String? warningKey;

  const LiveRecordingState({
    this.isRecording = false,
    this.callerNumber = '',
    this.appSource = '',
    this.amplitude = 0.0,
    this.elapsedSeconds = 0,
    this.mediaType = 'audio',
    this.warningKey,
  });

  LiveRecordingState copyWith({
    bool? isRecording,
    String? callerNumber,
    String? appSource,
    double? amplitude,
    int? elapsedSeconds,
    String? mediaType,
    String? warningKey,
    bool clearWarning = false,
  }) {
    return LiveRecordingState(
      isRecording: isRecording ?? this.isRecording,
      callerNumber: callerNumber ?? this.callerNumber,
      appSource: appSource ?? this.appSource,
      amplitude: amplitude ?? this.amplitude,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mediaType: mediaType ?? this.mediaType,
      warningKey: clearWarning ? null : warningKey ?? this.warningKey,
    );
  }
}

class LiveRecordingNotifier extends StateNotifier<LiveRecordingState> {
  final NativeBridge _bridge;
  StreamSubscription<RecordingEvent>? _subscription;
  Timer? _durationTimer;

  LiveRecordingNotifier(this._bridge) : super(const LiveRecordingState()) {
    _init();
  }

  void _init() {
    _subscription = _bridge.recordingStream.listen((event) {
      if (event is RecordingStartedEvent) {
        state = state.copyWith(
          isRecording: true,
          callerNumber: event.callerNumber,
          appSource: event.appSource,
          mediaType: event.mediaType,
          elapsedSeconds: 0,
          amplitude: 0.1,
          clearWarning: true,
        );
        _startTimer();
      } else if (event is AmplitudeUpdateEvent) {
        if (state.isRecording) {
          state = state.copyWith(amplitude: event.amplitude);
        }
      } else if (event is RecordingCompletedEvent) {
        _stopTimer();
        state = state.copyWith(
          isRecording: false,
          amplitude: 0.0,
          elapsedSeconds: 0,
        );
      } else if (event is RecordingWarningEvent) {
        state = state.copyWith(warningKey: event.messageKey);
      }
    });

    // Check initial recording state
    _bridge.isRecording().then((recording) {
      if (recording && !state.isRecording) {
        state = state.copyWith(isRecording: true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRecording) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> toggleManualRecording() async {
    if (state.isRecording) {
      if (state.mediaType == 'video') {
        await _bridge.stopVideoRecording();
      } else {
        await _bridge.stopManualRecording();
      }
    } else {
      await _bridge.startManualRecording();
    }
  }

  Future<bool> startManualAudioRecording() async {
    if (state.isRecording) return false;
    return _bridge.startManualRecording(audioSource: 'mic_only');
  }

  Future<bool> startManualVideoRecording() async {
    if (state.isRecording) return false;
    return _bridge.startVideoRecording(
      audioSource: 'mic_only',
    );
  }

  Future<void> stopRecording() async {
    if (state.isRecording) {
      if (state.mediaType == 'video') {
        await _bridge.stopVideoRecording();
      } else {
        await _bridge.stopManualRecording();
      }
    }
  }

  void clearWarning() => state = state.copyWith(clearWarning: true);

  @override
  void dispose() {
    _stopTimer();
    _subscription?.cancel();
    super.dispose();
  }
}
