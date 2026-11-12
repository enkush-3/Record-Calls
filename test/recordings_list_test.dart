import 'package:flutter_test/flutter_test.dart';
import 'package:record_calls/core/database/database_helper.dart';
import 'package:record_calls/core/database/recording_entity.dart';
import 'package:record_calls/core/database/recordings_repository.dart';
import 'package:record_calls/features/recordings/state/recordings_notifier.dart';
import 'settings_test.dart';

class _RecordingRepository extends RecordingsRepository {
  final List<RecordingEntity> items;

  _RecordingRepository(this.items) : super(DatabaseHelper());

  @override
  Future<List<RecordingEntity>> getRecordings({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
  }) async {
    return items.where((item) {
      if (favoritesOnly && !item.isFavorite) return false;
      if (appSource != null && item.appSource != appSource) return false;
      if (mediaType != null && item.mediaType != mediaType) return false;
      return true;
    }).toList();
  }
}

void main() {
  test(
    'loads and filters every matching recording without pagination',
    () async {
      final items = List.generate(
        40,
        (i) => RecordingEntity(
          id: i + 1,
          filePath: '/rec/test_$i.m4a',
          callerName: 'Caller $i',
          appSource: i < 30 ? 'WeChat' : 'Cellular',
          durationSec: 10,
          fileSize: 1000,
          createdAt: 1000 + i,
          mediaType: i.isEven ? 'audio' : 'video',
        ),
      );
      final notifier = RecordingsNotifier(
        _RecordingRepository(items),
        FakeNativeBridge(),
      );
      addTearDown(notifier.dispose);

      await notifier.loadRecordings();
      expect(notifier.state.recordings, hasLength(40));

      notifier.applyFilterAndSort(appSource: 'WeChat');
      await notifier.loadRecordings();
      expect(notifier.state.recordings, hasLength(30));

      notifier.applyFilterAndSort(appSource: 'WeChat', mediaType: 'video');
      await notifier.loadRecordings();
      expect(notifier.state.recordings, hasLength(15));
    },
  );
}
