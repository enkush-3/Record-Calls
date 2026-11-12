import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/bridge/native_bridge.dart';
import 'settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final NativeBridge _bridge;
  final SharedPreferences? _prefs;
  static const String _cloudAccountKey = 'cloud_account_data';
  static const String _audioSourceKey = 'audio_recording_source';

  SettingsNotifier(this._bridge, [this._prefs])
    : super(SettingsState.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final currentDir = await _bridge.getStorageDirectory();
      final available = await _bridge.getAvailableStorageDirectories();
      final info = await _bridge.getStorageDirectoryInfo();

      String savedAudioSource = 'both';
      if (_prefs != null) {
        await _prefs.remove(_cloudAccountKey);
        savedAudioSource = _prefs.getString(_audioSourceKey) ?? 'both';
      }

      if (!mounted) return;
      state = state.copyWith(
        storageDirectory: currentDir,
        availableDirectories: available,
        freeSpaceBytes: (info['freeSpaceBytes'] as num?)?.toInt() ?? 0,
        totalSpaceBytes: (info['totalSpaceBytes'] as num?)?.toInt() ?? 0,
        recordingFilesCount:
            (info['recordingFilesCount'] as num?)?.toInt() ?? 0,
        isWritable: (info['isWritable'] as bool?) ?? true,
        audioRecordingSource: _prefs != null
            ? savedAudioSource
            : state.audioRecordingSource,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Тохиргоо ачаалахад алдаа гарлаа: $e',
      );
    }
  }

  Future<bool> setStorageDirectory(String newPath) async {
    final cleanPath = newPath.trim().replaceAll('"', '').replaceAll("'", "");
    if (cleanPath.isEmpty) {
      state = state.copyWith(errorMessage: 'Хавтасны зам хоосон байж болохгүй');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null, message: null);
    try {
      final success = await _bridge.setStorageDirectory(cleanPath);
      if (success) {
        final currentDir = await _bridge.getStorageDirectory();
        final info = await _bridge.getStorageDirectoryInfo();

        state = state.copyWith(
          storageDirectory: currentDir,
          freeSpaceBytes: (info['freeSpaceBytes'] as num?)?.toInt() ?? 0,
          totalSpaceBytes: (info['totalSpaceBytes'] as num?)?.toInt() ?? 0,
          recordingFilesCount:
              (info['recordingFilesCount'] as num?)?.toInt() ?? 0,
          isWritable: (info['isWritable'] as bool?) ?? true,
          isSaving: false,
          message: 'Бичлэг хадгалах хавтас амжилттай солигдлоо.',
        );
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage:
              'Энэ хавтас руу хандах боломжгүй эсвэл бичих зөвшөөрөлгүй байна.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Алдаа гарлаа: $e');
      return false;
    }
  }

  Future<void> resetToDefaultDirectory() async {
    state = state.copyWith(isSaving: true, errorMessage: null, message: null);
    try {
      final defaultDir = await _bridge.resetStorageDirectory();
      final info = await _bridge.getStorageDirectoryInfo();

      state = state.copyWith(
        storageDirectory: defaultDir,
        freeSpaceBytes: (info['freeSpaceBytes'] as num?)?.toInt() ?? 0,
        totalSpaceBytes: (info['totalSpaceBytes'] as num?)?.toInt() ?? 0,
        recordingFilesCount:
            (info['recordingFilesCount'] as num?)?.toInt() ?? 0,
        isWritable: (info['isWritable'] as bool?) ?? true,
        isSaving: false,
        message: 'Үндсэн хавтас сэргээгдлээ.',
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Алдаа гарлаа: $e');
    }
  }

  Future<void> setAudioRecordingSource(String source) async {
    if (state.audioRecordingSource == source) return;
    state = state.copyWith(audioRecordingSource: source);
    if (_prefs != null) {
      await _prefs.setString(_audioSourceKey, source);
    }
    await _bridge.setAudioRecordingSource(source);
    state = state.copyWith(
      message: source == 'both'
          ? 'Хоёр талын дуу зэрэг бичигдэнэ'
          : (source == 'mic_only'
                ? 'Зөвхөн өөрийн дуу хоолой (Mic) бичигдэнэ'
                : 'Зөвхөн ярьж байгаа хүний дуу (Remote) бичигдэнэ'),
    );
  }

  void clearMessage() {
    state = state.copyWith(message: null, errorMessage: null);
  }
}
