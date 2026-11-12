import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record_calls/core/bridge/native_bridge.dart';
import 'package:record_calls/core/bridge/permission_status_model.dart';
import 'package:record_calls/core/bridge/recording_event.dart';
import 'package:record_calls/core/di/providers.dart';
import 'package:record_calls/features/settings/state/settings_notifier.dart';
import 'package:record_calls/features/settings/ui/settings_screen.dart';

class FakeNativeBridge extends NativeBridge {
  String currentPath = '/storage/emulated/0/Android/data/test/files/Recordings';
  bool autoRecord = true;

  @override
  Future<String> getStorageDirectory() async => currentPath;

  @override
  Future<bool> setStorageDirectory(String path) async {
    if (path.isEmpty || path.contains('invalid')) return false;
    currentPath = path;
    return true;
  }

  @override
  Future<String> resetStorageDirectory() async {
    currentPath = '/storage/emulated/0/Android/data/test/files/Recordings';
    return currentPath;
  }

  @override
  Future<List<Map<String, String>>> getAvailableStorageDirectories() async {
    return [
      {
        'title': 'Аппын гадаад хавтас (Үндсэн)',
        'path': '/storage/emulated/0/Android/data/test/files/Recordings',
        'isDefault': 'true',
        'description': 'Системийн хамгаалалттай найдвартай хавтас',
      },
      {
        'title': 'Аппын дотоод хавтас (Нууцлагдмал)',
        'path': '/data/user/0/test/files/Recordings',
        'isDefault': 'false',
        'description': 'Бусад апп харах боломжгүй хувийн санах ой',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getStorageDirectoryInfo() async {
    return {
      'path': currentPath,
      'exists': true,
      'isWritable': true,
      'freeSpaceBytes': 45 * 1024 * 1024 * 1024,
      'totalSpaceBytes': 128 * 1024 * 1024 * 1024,
      'recordingFilesCount': 8,
    };
  }

  @override
  Future<bool> isAutoRecordEnabled() async => autoRecord;

  @override
  Future<bool> setAutoRecordEnabled(bool enabled) async {
    autoRecord = enabled;
    return true;
  }

  @override
  Stream<RecordingEvent> get recordingStream => const Stream.empty();

  @override
  Future<bool> isRecording() async => false;

  @override
  Future<List<Map<String, dynamic>>> fetchPendingRecordings() async => [];

  @override
  Future<PermissionStatusModel> getPermissionsStatus() async {
    return PermissionStatusModel(
      mic: true,
      phone: true,
      notification: true,
      accessibility: true,
      batteryIgnored: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier Unit Tests', () {
    test(
      'loadSettings initializes storageDirectory and available directories with metrics',
      () async {
        final fakeBridge = FakeNativeBridge();
        final notifier = SettingsNotifier(fakeBridge);

        await notifier.loadSettings();

        expect(notifier.state.storageDirectory, fakeBridge.currentPath);
        expect(notifier.state.availableDirectories.length, 2);
        expect(notifier.state.freeSpaceBytes, greaterThan(0));
        expect(notifier.state.recordingFilesCount, 8);
        expect(notifier.state.isWritable, true);
        expect(notifier.state.isLoading, false);
      },
    );

    test('setStorageDirectory updates directory successfully', () async {
      final fakeBridge = FakeNativeBridge();
      final notifier = SettingsNotifier(fakeBridge);
      await notifier.loadSettings();

      final success = await notifier.setStorageDirectory(
        '/custom/path/recordings',
      );
      expect(success, true);
      expect(notifier.state.storageDirectory, '/custom/path/recordings');
      expect(notifier.state.message, isNotNull);
    });

    test('setStorageDirectory rejects empty or invalid path', () async {
      final fakeBridge = FakeNativeBridge();
      final notifier = SettingsNotifier(fakeBridge);
      await notifier.loadSettings();

      final successEmpty = await notifier.setStorageDirectory('   ');
      expect(successEmpty, false);
      expect(notifier.state.errorMessage, contains('хоосон'));

      final successInvalid = await notifier.setStorageDirectory('/invalid/dir');
      expect(successInvalid, false);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('resetToDefaultDirectory restores default path', () async {
      final fakeBridge = FakeNativeBridge();
      final notifier = SettingsNotifier(fakeBridge);
      await notifier.setStorageDirectory('/custom/path/recordings');
      expect(notifier.state.storageDirectory, '/custom/path/recordings');

      await notifier.resetToDefaultDirectory();
      expect(
        notifier.state.storageDirectory,
        '/storage/emulated/0/Android/data/test/files/Recordings',
      );
      expect(notifier.state.message, isNotNull);
    });
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'renders SettingsScreen with theme, storage metrics, and about sections',
      (WidgetTester tester) async {
        final fakeBridge = FakeNativeBridge();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [nativeBridgeProvider.overrideWithValue(fakeBridge)],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Check AppBar Title
        expect(find.text('Тохиргоо'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);

        // Check Theme Segments
        expect(find.text('Систем'), findsOneWidget);
        expect(find.text('Цайвар'), findsOneWidget);
        expect(find.text('Харанхуй'), findsOneWidget);

        // Check Storage section and metrics
        expect(find.text('Идэвхтэй хавтас'), findsOneWidget);
        expect(find.text('Байршил солих'), findsOneWidget);
        expect(find.text('Үндсэн зам'), findsOneWidget);
        expect(find.text('Бичих эрхтэй'), findsOneWidget);
        expect(find.textContaining('чөлөөтэй'), findsOneWidget);
        expect(find.text('8 файл'), findsOneWidget);

        // Scroll to reveal About app section
        await tester.scrollUntilVisible(
          find.text('Record Call'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Record Call'), findsOneWidget);
        expect(find.text('Хувилбар 1.0.0+1 (No Ads)'), findsOneWidget);
      },
    );

    testWidgets(
      'Change Directory bottom sheet shows available options and updates path',
      (WidgetTester tester) async {
        final fakeBridge = FakeNativeBridge();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [nativeBridgeProvider.overrideWithValue(fakeBridge)],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Tap 'Байршил солих'
        await tester.tap(find.text('Байршил солих'));
        await tester.pumpAndSettle();

        // Verify bottom sheet title and options
        expect(find.text('Хадгалах хавтас сонгох'), findsOneWidget);
        expect(find.text('Аппын гадаад хавтас (Үндсэн)'), findsOneWidget);
        expect(find.text('Аппын дотоод хавтас (Нууцлагдмал)'), findsOneWidget);
        expect(
          find.text('Өөр замын хаяг оруулах (Custom Path)'),
          findsOneWidget,
        );

        // Tap the internal storage folder option
        await tester.tap(find.text('Аппын дотоод хавтас (Нууцлагдмал)'));
        await tester.pumpAndSettle();

        // Bottom sheet should dismiss and path should update
        expect(find.text('Хадгалах хавтас сонгох'), findsNothing);
        expect(find.text('/data/user/0/test/files/Recordings'), findsOneWidget);
      },
    );
  });
}
