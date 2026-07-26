# GPS Camera

GPS Camera is a Flutter mobile app for capturing photos and videos with location context. It combines a camera-first capture flow, live GPS stamping, a media gallery, map/location views, sharing, and local metadata persistence for geotagged memories.

## Highlights

- **Photo and video capture** with front/back camera switching, flash controls, zoom presets, and animated capture feedback.
- **Live GPS stamp overlay** showing address, coordinates, date, and time while capturing media.
- **Map previews** powered by OpenStreetMap through `flutter_map`, with Google Maps service support available in the codebase.
- **Gallery management** with grid thumbnails, video duration badges, multi-select, delete, and share actions.
- **Detail and result screens** for reviewing captures, playing video, exporting QR map links, saving to the camera roll, and sharing media.
- **Metadata sidecars** (`.gps.json`) to preserve captured location details alongside saved media.
- **Settings, account, and locations screens** for app configuration and navigation beyond the primary capture/gallery flows.

## Tech stack

- **Framework:** Flutter / Dart
- **Camera:** `camera`
- **Location:** `geolocator`, `geocoding`
- **Maps:** `flutter_map`, `latlong2`, plus Google Maps-related dependencies
- **Media:** `photo_manager`, `image_gallery_saver_plus`, `video_player`, `image`, `flutter_image_compress`
- **Sharing and export:** `share_plus`, `qr_flutter`
- **Persistence and services:** `shared_preferences`, app file storage, metadata sidecars
- **Reliability/connectivity:** `connectivity_plus`, Firebase Core, Firebase Crashlytics

See [`pubspec.yaml`](pubspec.yaml) for the authoritative dependency list.

## Project structure

```text
lib/
├── app.dart                       # App shell, theme, and route setup
├── main.dart                      # Bootstrap, orientation, and permission startup
├── core/                          # Shared constants, theme, utilities, and widgets
├── features/                      # Feature-first camera, gallery, detail, result, locations, settings, account UI
├── models/                        # Captured media, location, photo, and settings models
├── providers/                     # App-level providers
├── screens/                       # Legacy/top-level screens still present in the app
├── services/                      # Camera, gallery, location, map, storage, backup, and error services
├── utils/                         # Image, EXIF, and overlay helpers
└── widgets/                       # Shared map/geo overlay widgets
```

Important platform files:

- `android/app/src/main/AndroidManifest.xml` — Android permissions and Google Maps metadata hook.
- `android/app/src/main/res/values/strings.xml` — Android string resources, including the Google Maps key placeholder.
- `ios/Runner/Info.plist` — iOS camera, microphone, location, and photo-library usage descriptions.

## Prerequisites

Install and configure the following before running the app:

- Flutter SDK on the stable channel
- Dart SDK included with Flutter
- Android Studio with Flutter and Dart plugins
- Android SDK and an Android emulator or physical Android device
- Xcode and CocoaPods for iOS development on macOS

Verify your environment with:

```bash
flutter doctor -v
```

## Getting started

1. Clone the repository:

   ```bash
   git clone <your-repo-url>
   cd GPS_Camera
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app on a connected device or emulator:

   ```bash
   flutter run
   ```

For the best camera and GPS results, test on a physical device with location services enabled.

## Configuration

### Permissions

The app requests runtime access to:

- Camera
- Microphone for video recording
- Precise and approximate location
- Photo library/media storage
- Internet access for map tiles and network-backed services

Android declarations live in `android/app/src/main/AndroidManifest.xml`; iOS usage descriptions live in `ios/Runner/Info.plist`.

### Maps

The primary in-app map preview uses OpenStreetMap via `flutter_map`, so local map thumbnails do not require a paid API key.

The project also includes Google Maps dependencies and Android metadata. If you enable Google Maps features, add your key to the Android string resource referenced by the manifest and configure the iOS Google Maps SDK in `ios/Runner/AppDelegate.swift`.

### Firebase Crashlytics

Firebase packages are included for crash reporting support. If Crashlytics is enabled for a deployment target, make sure the platform-specific Firebase configuration files are added and generated according to the Firebase Flutter setup flow.

## Common commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter build ios
```

## Troubleshooting

### Flutter or Dart command not found

Install Flutter and ensure the Flutter `bin` directory is on your `PATH`, then rerun `flutter doctor -v`.

### Camera preview does not start

- Confirm camera permission is granted in system settings.
- Prefer a physical device if emulator camera support is unreliable.
- Restart the app after changing OS-level permissions.

### Location stamp is missing or inaccurate

- Enable device location services.
- Grant precise location permission when prompted.
- Test outdoors or near a window for a better GPS fix.

### Media does not appear in the device gallery

- Confirm photo/media permissions are granted.
- Check platform-specific media access rules for the Android or iOS version under test.
- Try `flutter clean`, reinstall the app, and capture new media.

### Build issues after dependency changes

```bash
flutter clean
flutter pub get
flutter analyze
```

Then retry the target build or run command.

## Additional documentation

- [`GPS_CAMERA_APP.md`](GPS_CAMERA_APP.md) — broader implementation plan and roadmap notes.
- [Flutter install guide](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio)
- [Flutter packages](https://pub.dev/)
