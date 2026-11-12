import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record_calls/core/database/database_helper.dart';
import 'package:record_calls/core/database/recording_entity.dart';
import 'package:record_calls/core/database/recordings_repository.dart';
import 'package:record_calls/core/di/providers.dart';
import 'package:record_calls/features/recordings/ui/home_screen.dart';
import 'package:record_calls/features/recordings/ui/widgets/recording_card.dart';
import 'package:record_calls/features/settings/ui/settings_screen.dart';
import 'package:record_calls/main.dart';
import 'settings_test.dart';

class FakeRecordingsRepository extends RecordingsRepository {
  FakeRecordingsRepository() : super(DatabaseHelper());

  @override
  Future<List<RecordingEntity>> getRecordings({
    String? searchQuery,
    String? appSource,
    String? mediaType,
    bool favoritesOnly = false,
  }) async {
    return [];
  }

  @override
  Future<int> syncPendingRecordings(List<Map<String, dynamic>> pending) async => 0;
}

void main() {
  testWidgets('App smoke test initializes without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RecordCallApp()));
    expect(find.byType(RecordCallApp), findsOneWidget);
  });

  testWidgets('HomeScreen displays Record Call and navigation works without ads', (
    WidgetTester tester,
  ) async {
    final fakeBridge = FakeNativeBridge();
    final fakeRepo = FakeRecordingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nativeBridgeProvider.overrideWithValue(fakeBridge),
          recordingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title is Record Call
    expect(find.text('Record Call'), findsOneWidget);

    // Verify Search Bar and Controls exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Авто'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Verify NO banner or ad widgets exist
    expect(find.byKey(const Key('adaptive_banner_ad')), findsNothing);

    // Verify Quick Theme Toggle button exists and can be tapped
    final themeToggle = find.byTooltip('Харанхуй горим');
    expect(themeToggle, findsOneWidget);
    await tester.tap(themeToggle);
    await tester.pumpAndSettle();

    // Verify Theme switched to dark
    expect(find.byTooltip('Цайвар горим'), findsOneWidget);

    // Tap Settings icon and verify it pushes SettingsScreen
    final settingsButton = find.byTooltip('Тохиргоо');
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Тохиргоо'), findsOneWidget);
  });

  testWidgets('RecordingCard displays details dialog with storage file path', (
    WidgetTester tester,
  ) async {
    const recording = RecordingEntity(
      id: 1,
      filePath: '/storage/emulated/0/Android/data/test/files/Recordings/REC_Cellular_12345.m4a',
      callerName: '+97699112233',
      appSource: 'Cellular',
      durationSec: 65,
      fileSize: 1048576,
      createdAt: 1700000000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordingCard(
            recording: recording,
            onPlay: () {},
            onToggleFavorite: () {},
            onUpdateNotes: (_) {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Info button
    final infoButton = find.byTooltip('Байршил & Мэдээлэл');
    expect(infoButton, findsOneWidget);
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    // Verify Details dialog content
    expect(find.text('Бичлэгийн дэлгэрэнгүй'), findsOneWidget);
    expect(find.text(recording.filePath), findsOneWidget);
    expect(find.text('Зам хуулах'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Хаах'));
    await tester.pumpAndSettle();
    expect(find.text('Бичлэгийн дэлгэрэнгүй'), findsNothing);
  });
}
