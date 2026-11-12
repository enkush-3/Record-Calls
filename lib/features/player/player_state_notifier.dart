import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/database/recording_entity.dart';

class PlayerStateModel {
  final RecordingEntity? recording;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isLoading;

  const PlayerStateModel({
    this.recording,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isLoading = false,
  });

  PlayerStateModel copyWith({
    RecordingEntity? recording,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isLoading,
  }) {
    return PlayerStateModel(
      recording: recording ?? this.recording,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlayerStateNotifier extends StateNotifier<PlayerStateModel> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  PlayerStateNotifier() : super(const PlayerStateModel()) {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    _stateSub = _player.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        isLoading: ps.processingState == ProcessingState.buffering ||
            ps.processingState == ProcessingState.loading,
      );
    });
  }

  Future<void> playRecording(RecordingEntity recording) async {
    try {
      state = state.copyWith(
        recording: recording,
        position: Duration.zero,
        duration: Duration(seconds: recording.durationSec),
        isLoading: true,
      );

      await _player.setFilePath(recording.filePath);
      await _player.setSpeed(state.speed);
      await _player.play();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skip(int seconds) async {
    final target = _player.position + Duration(seconds: seconds);
    final clamped = target.inMilliseconds.clamp(
      0,
      state.duration.inMilliseconds,
    );
    await _player.seek(Duration(milliseconds: clamped));
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _player.setSpeed(speed);
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final playerProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerStateModel>((ref) {
  return PlayerStateNotifier();
});
