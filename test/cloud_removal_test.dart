import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record_calls/features/settings/state/settings_notifier.dart';
import 'settings_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'clears a previously saved cloud account from local preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'cloud_account_data': '{"provider":"google_drive"}',
      });
      final preferences = await SharedPreferences.getInstance();
      final notifier = SettingsNotifier(FakeNativeBridge(), preferences);
      addTearDown(notifier.dispose);

      await notifier.loadSettings();

      expect(preferences.containsKey('cloud_account_data'), isFalse);
    },
  );
}
