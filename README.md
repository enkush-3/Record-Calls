# Record Call
Record Call is a Flutter app for managing audio and screen recordings on Android. Recordings are saved locally on the device.

## Features
- Automatic call detection for supported communication apps
- Audio and screen recording tests
- Recording search, filters, playback, and organization
- Local recording storage ([layout](docs/RECORDING_STORAGE_LAYOUT.md))

Recording behavior depends on Android permissions, device capabilities, and each source app's audio capture policy. Android may restrict recording the other side of a phone or VoIP call.

## Requirements
```
- Flutter SDK
- Android SDK
```

## Run locally
```
flutter pub get
flutter run
```

### Build
Android release APK:
```
flutter build apk --release
```
The APK is created at build/app/outputs/flutter-apk/app-release.apk.

## Privacy
Recordings are stored locally on the device.

## License
Anyone can use this app.
