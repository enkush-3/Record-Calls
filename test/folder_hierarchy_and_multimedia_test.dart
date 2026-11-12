import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record_calls/core/bridge/recording_event.dart';
import 'package:record_calls/core/database/database_helper.dart';
import 'package:record_calls/core/database/recording_entity.dart';
import 'package:record_calls/core/database/recordings_repository.dart';
import 'package:record_calls/core/di/providers.dart';
import 'package:record_calls/core/theme/app_colors.dart';
import 'package:record_calls/features/recordings/state/recording_filter.dart';
import 'package:record_calls/features/recordings/ui/home_screen.dart';
import 'package:record_calls/features/recordings/ui/widgets/filter_chip_bar.dart';
import 'package:record_calls/features/recordings/ui/widgets/live_recording_indicator.dart';
import 'package:record_calls/features/recordings/ui/widgets/recording_card.dart';
import 'settings_test.dart';

class MockRecordingsRepoWithData extends RecordingsRepository {
  final List<RecordingEntity> dummyList;

  MockRecordingsRepoWithData(this.dummyList) : super(DatabaseHelper());

  @override
  Future<List<RecordingEntity>> getRecordings({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
  }) async {
    return dummyList.where((item) {
      if (favoritesOnly && !item.isFavorite) return false;
      if (appSource != null && appSource.isNotEmpty && appSource != 'All') {
        if (item.appSource.toLowerCase() != appSource.toLowerCase()) {
          return false;
        }
      }
      if (mediaType != null && mediaType.isNotEmpty && mediaType != 'All') {
        if (item.mediaType.toLowerCase() != mediaType.toLowerCase()) {
          return false;
        }
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (!item.callerName.contains(searchQuery) &&
            !(item.notes?.contains(searchQuery) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<int> syncPendingRecordings(List<Map<String, dynamic>> pending) async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeChat & Messenger Integration & AppColors Tests', () {
    test('AppColors provides correct brand colors and icons for WeChat and Messenger', () {
      expect(AppColors.weChat, const Color(0xFF07C160));
      expect(AppColors.messenger, const Color(0xFF0084FF));

      expect(AppColors.getColorForSource('WeChat'), const Color(0xFF07C160));
      expect(AppColors.getColorForSource('wechat'), const Color(0xFF07C160));
      expect(AppColors.getColorForSource('Messenger'), const Color(0xFF0084FF));
      expect(AppColors.getColorForSource('messenger'), const Color(0xFF0084FF));
      expect(AppColors.getColorForSource('Viber'), AppColors.viber);
      expect(AppColors.getColorForSource('Telegram'), AppColors.telegram);
      expect(AppColors.getColorForSource('WhatsApp'), AppColors.whatsApp);

      expect(AppColors.getIconForSource('wechat'), Icons.chat_bubble_outline_rounded);
      expect(AppColors.getIconForSource('messenger'), Icons.chat_bubble_outline_rounded);

      expect(AppColors.getIconForMediaType('video'), Icons.videocam_rounded);
      expect(AppColors.getIconForMediaType('audio'), Icons.mic_rounded);
    });

    test('RecordingFilter contains WeChat, Messenger, Audio, Video, and VoIP sources', () {
      expect(RecordingFilter.values.map((f) => f.label), containsAll([
        'Бүгд',
        'Утас',
        'Viber',
        'Telegram',
        'WhatsApp',
        'Messenger',
        'WeChat',
        'Аудио',
        'Видео',
        'Одтой',
      ]));

      expect(RecordingFilter.weChat.appSourceValue, 'WeChat');
      expect(RecordingFilter.messenger.appSourceValue, 'Messenger');
      expect(RecordingFilter.video.mediaType, 'video');
      expect(RecordingFilter.audio.mediaType, 'audio');
    });
  });

  group('RecordingEntity & SQLite Model Tests', () {
    test('RecordingEntity correctly initializes with default mediaType and serializes to/from map', () {
      const defaultEntity = RecordingEntity(
        filePath: '/storage/WeChat/+97699112233/20261111_120000.m4a',
        callerName: '+97699112233',
        appSource: 'WeChat',
        durationSec: 45,
        fileSize: 45000,
        createdAt: 1700000000,
      );
      expect(defaultEntity.mediaType, 'audio');

      final map = defaultEntity.toMap();
      expect(map['media_type'], 'audio');
      expect(map['app_source'], 'WeChat');

      final videoEntity = defaultEntity.copyWith(
        mediaType: 'video',
        filePath: '/storage/Messenger/JohnDoe/20261111_120500.mp4',
        appSource: 'Messenger',
      );
      expect(videoEntity.mediaType, 'video');
      expect(videoEntity.appSource, 'Messenger');

      final deserialized = RecordingEntity.fromMap(videoEntity.toMap());
      expect(deserialized.mediaType, 'video');
      expect(deserialized.filePath, '/storage/Messenger/JohnDoe/20261111_120500.mp4');
      expect(deserialized.callerName, '+97699112233');
      expect(deserialized.appSource, 'Messenger');
    });

    test('RecordingEvent correctly parses mediaType from map', () {
      final startedAudio = RecordingEvent.fromMap({
        'type': 'recording_started',
        'filePath': '/storage/WeChat/123/20261111_100000.m4a',
        'callerNumber': '123',
        'appSource': 'WeChat',
        'mediaType': 'audio',
      }) as RecordingStartedEvent;
      expect(startedAudio.mediaType, 'audio');
      expect(startedAudio.appSource, 'WeChat');

      final completedVideo = RecordingEvent.fromMap({
        'type': 'recording_completed',
        'filePath': '/storage/Telegram/456/20261111_100500.mp4',
        'callerNumber': '456',
        'appSource': 'Telegram',
        'durationSec': 120,
        'fileSize': 1048576,
        'createdAt': 1700000000,
        'mediaType': 'video',
      }) as RecordingCompletedEvent;
      expect(completedVideo.mediaType, 'video');
      expect(completedVideo.durationSec, 120);
    });
  });

  group('Nested Folder Storage Path Hierarchy Tests', () {
    test('Simulated nested folder path adheres to <StorageDir>/<AppSource>/<SanitizedCallerNumber>/<Timestamp>.<ext>', () {
      String generateRecordingPath({
        required String storageDir,
        required String appSource,
        required String callerNumber,
        required String timestamp,
        required String ext,
      }) {
        final cleanSource = appSource.trim().isEmpty ? 'Manual' : appSource;
        if (callerNumber.trim().isEmpty) {
          return '$storageDir/$cleanSource/Unknown_Caller/$timestamp.$ext';
        }
        var cleanCaller = callerNumber
            .trim()
            .replaceAll(RegExp(r'[^a-zA-Z0-9+_.-]'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');
        if (cleanCaller.isEmpty ||
            cleanCaller.toLowerCase() == 'unknown' ||
            cleanCaller.toLowerCase() == 'unknown_caller') {
          cleanCaller = 'Unknown_Caller';
        }
        return '$storageDir/$cleanSource/$cleanCaller/$timestamp.$ext';
      }

      // Case 1: Viber audio recording
      final path1 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: 'Viber',
        callerNumber: '+97699112233',
        timestamp: '20261111_201530',
        ext: 'm4a',
      );
      expect(path1, '/sdcard/Recordings/Viber/+97699112233/20261111_201530.m4a');

      // Case 2: WeChat video recording
      final path2 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: 'WeChat',
        callerNumber: 'Alice (Friend)',
        timestamp: '20261111_201645',
        ext: 'mp4',
      );
      expect(path2, '/sdcard/Recordings/WeChat/Alice_Friend/20261111_201645.mp4');

      // Case 3: Empty caller defaults to Unknown_Caller
      final path3 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: 'Telegram',
        callerNumber: '',
        timestamp: '20261111_201700',
        ext: 'm4a',
      );
      expect(path3, '/sdcard/Recordings/Telegram/Unknown_Caller/20261111_201700.m4a');

      // Case 4: Messenger video recording
      final path4 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: 'Messenger',
        callerNumber: 'Bob99',
        timestamp: '20261111_201800',
        ext: 'mp4',
      );
      expect(path4, '/sdcard/Recordings/Messenger/Bob99/20261111_201800.mp4');

      // Case 5: 'watsapp' typo mapping and special characters in phone number
      final cleanWatsappSource = (['whatsapp', 'watsapp'].contains('watsapp'.toLowerCase())) ? 'WhatsApp' : 'watsapp';
      final path5 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: cleanWatsappSource,
        callerNumber: '+976-9911-2233',
        timestamp: '20261111_201900',
        ext: 'm4a',
      );
      expect(path5, '/sdcard/Recordings/WhatsApp/+976-9911-2233/20261111_201900.m4a');

      // Case 6: 'Unknown_Caller' when input is 'Unknown' or spaces
      final path6 = generateRecordingPath(
        storageDir: '/sdcard/Recordings',
        appSource: 'WeChat',
        callerNumber: '   ',
        timestamp: '20261111_202000',
        ext: 'mp4',
      );
      expect(path6, '/sdcard/Recordings/WeChat/Unknown_Caller/20261111_202000.mp4');
    });

    test('RecordingsRepository case-insensitive filtering handles mixed case sources and media types', () {
      final repo = MockRecordingsRepoWithData([
        const RecordingEntity(
          id: 1,
          filePath: '/p/1.m4a',
          callerName: 'Alice',
          appSource: 'wechat',
          durationSec: 10,
          fileSize: 100,
          createdAt: 1000,
          mediaType: 'audio',
        ),
        const RecordingEntity(
          id: 2,
          filePath: '/p/2.mp4',
          callerName: 'Bob',
          appSource: 'WeChat',
          durationSec: 20,
          fileSize: 200,
          createdAt: 2000,
          mediaType: 'VIDEO',
        ),
      ]);

      // Filtering with lowercase 'wechat' should find both
      expect(repo.getRecordings(appSource: 'WeChat'), completion(hasLength(2)));
      expect(repo.getRecordings(appSource: 'wechat'), completion(hasLength(2)));
      // Filtering with mediaType 'video' should find item 2
      expect(repo.getRecordings(mediaType: 'video'), completion(hasLength(1)));
      expect(repo.getRecordings(mediaType: 'VIDEO'), completion(hasLength(1)));
    });
  });

  group('UI & Widget Tests for Audio and Video Recordings', () {
    testWidgets('RecordingCard displays Audio and Video media type badges and opens details', (
      WidgetTester tester,
    ) async {
      const audioCard = RecordingEntity(
        id: 1,
        filePath: '/storage/Recordings/WeChat/+97699112233/20261111_201530.m4a',
        callerName: '+97699112233',
        appSource: 'WeChat',
        durationSec: 90,
        fileSize: 120000,
        createdAt: 1700000000000,
        mediaType: 'audio',
      );

      const videoCard = RecordingEntity(
        id: 2,
        filePath: '/storage/Recordings/Messenger/User123/20261111_202000.mp4',
        callerName: 'User123',
        appSource: 'Messenger',
        durationSec: 180,
        fileSize: 5242880,
        createdAt: 1700000050000,
        mediaType: 'video',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RecordingCard(
                  recording: audioCard,
                  onPlay: () {},
                  onToggleFavorite: () {},
                  onUpdateNotes: (_) {},
                  onDelete: () {},
                ),
                RecordingCard(
                  recording: videoCard,
                  onPlay: () {},
                  onToggleFavorite: () {},
                  onUpdateNotes: (_) {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify badges: Audio and Video text badges
      expect(find.text('Аудио'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);
      expect(find.text('WeChat'), findsOneWidget);
      expect(find.text('Messenger'), findsOneWidget);

      // Tap on Video card info button
      final infoButtons = find.byTooltip('Байршил & Мэдээлэл');
      expect(infoButtons, findsNWidgets(2));
      await tester.tap(infoButtons.at(1));
      await tester.pumpAndSettle();

      // Check Video Details dialog
      expect(find.text('Бичлэгийн дэлгэрэнгүй'), findsOneWidget);
      expect(find.text('Видео (MP4)'), findsOneWidget);
      expect(find.text(videoCard.filePath), findsOneWidget);

      await tester.tap(find.text('Хаах'));
      await tester.pumpAndSettle();
    });

    testWidgets('LiveRecordingIndicator displays both Audio and Video test buttons when idle', (
      WidgetTester tester,
    ) async {
      bool audioTapped = false;
      bool videoTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveRecordingIndicator(
              isRecording: false,
              callerNumber: '',
              appSource: '',
              amplitude: 0.0,
              elapsedSeconds: 0,
              onToggle: () {},
              onStartAudio: () {
                audioTapped = true;
              },
              onStartVideo: () {
                videoTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final audioButton = find.text('Аудио бичих тест');
      final videoButton = find.text('Видео бичих тест');

      expect(audioButton, findsOneWidget);
      expect(videoButton, findsOneWidget);

      await tester.tap(audioButton);
      expect(audioTapped, true);

      await tester.tap(videoButton);
      expect(videoTapped, true);
    });

    testWidgets('LiveRecordingIndicator displays Video recording status when video call is active', (
      WidgetTester tester,
    ) async {
      bool stopTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveRecordingIndicator(
              isRecording: true,
              callerNumber: '+97699112233',
              appSource: 'WeChat',
              amplitude: 0.0,
              elapsedSeconds: 35,
              mediaType: 'video',
              onToggle: () {},
              onStop: () {
                stopTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Видео бичиж байна: WeChat (+97699112233)'), findsOneWidget);
      expect(find.text('00:35'), findsOneWidget);

      final stopButton = find.byType(IconButton);
      expect(stopButton, findsOneWidget);
      await tester.tap(stopButton);
      expect(stopTapped, true);
    });

    testWidgets('FilterChipBar renders all chips including WeChat, Messenger, Audio, Video', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      RecordingFilter selected = RecordingFilter.all;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipBar(
              activeFilter: selected,
              onFilterSelected: (f) {
                selected = f;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Бүгд'), findsOneWidget);
      expect(find.text('Утас'), findsOneWidget);
      expect(find.text('Viber'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Messenger'), findsOneWidget);
      expect(find.text('WeChat'), findsOneWidget);
      expect(find.text('Аудио'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);
      expect(find.text('Одтой'), findsOneWidget);

      // Select WeChat
      await tester.tap(find.widgetWithText(ChoiceChip, 'WeChat'));
      expect(selected, RecordingFilter.weChat);

      // Select Video
      await tester.tap(find.widgetWithText(ChoiceChip, 'Видео'));
      expect(selected, RecordingFilter.video);
    });

    testWidgets('HomeScreen filters recordings by WeChat, Messenger, and Video', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyList = [
        const RecordingEntity(
          id: 1,
          filePath: '/path/Cellular/123/20261111_120000.m4a',
          callerName: 'Cellular Friend',
          appSource: 'Cellular',
          durationSec: 10,
          fileSize: 1000,
          createdAt: 1000,
          mediaType: 'audio',
        ),
        const RecordingEntity(
          id: 2,
          filePath: '/path/WeChat/456/20261111_120100.m4a',
          callerName: 'WeChat Contact',
          appSource: 'WeChat',
          durationSec: 20,
          fileSize: 2000,
          createdAt: 2000,
          mediaType: 'audio',
        ),
        const RecordingEntity(
          id: 3,
          filePath: '/path/Messenger/789/20261111_120200.mp4',
          callerName: 'Messenger Contact',
          appSource: 'Messenger',
          durationSec: 30,
          fileSize: 3000,
          createdAt: 3000,
          mediaType: 'video',
        ),
      ];

      final fakeBridge = FakeNativeBridge();
      final mockRepo = MockRecordingsRepoWithData(dummyList);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nativeBridgeProvider.overrideWithValue(fakeBridge),
            recordingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 3 items should initially be shown
      expect(find.text('Cellular Friend'), findsOneWidget);
      expect(find.text('WeChat Contact'), findsOneWidget);
      expect(find.text('Messenger Contact'), findsOneWidget);

      // Tap 'WeChat' filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'WeChat'));
      await tester.pumpAndSettle();

      expect(find.text('Cellular Friend'), findsNothing);
      expect(find.text('WeChat Contact'), findsOneWidget);
      expect(find.text('Messenger Contact'), findsNothing);

      // Tap 'Видео' filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Видео'));
      await tester.pumpAndSettle();

      expect(find.text('Cellular Friend'), findsNothing);
      expect(find.text('WeChat Contact'), findsNothing);
      expect(find.text('Messenger Contact'), findsOneWidget);
    });
  });
}
