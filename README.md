# GPS Camera (Flutter)

GPS Camera is a Flutter app for capturing photos/videos with GPS metadata, previewing captures in a gallery, and viewing stamped location details.

## What changed in the redesign

The app has been restructured around a new clean-feature layout and UI refresh:

- **Material 3 theme** with orange primary (`#F5A623`).
- **Camera-first flow** with:
  - full-screen preview,
  - photo/video mode toggle,
  - zoom controls (`0.5x`, `1x`, `2x`),
  - flash/front-back camera controls,
  - animated capture feedback.
- **Live location stamp card** overlay:
  - address + date + time,
  - mini map thumbnail (OpenStreetMap via `flutter_map`).
- **Gallery experience**:
  - grid thumbnails,
  - video duration badges,
  - multi-select, delete, and share.
- **Detail view**:
  - swipable media pages,
  - play/pause video UI,
  - QR code export for map links,
  - share/delete actions.
- **Result screen**:
  - auto-save to camera roll,
  - success banner,
  - one-tap share CTA.
- **Metadata sidecar support** (`.gps.json`) for location persistence.

## Project structure (new)

Key paths added/updated:

- `lib/core/` → theme, constants, utils, shared widgets.
- `lib/features/` → camera, gallery, detail, result, locations.
- `lib/models/` → `LocationInfo`, `CapturedMedia`.
- `lib/app.dart` + `lib/main.dart` → routing/bootstrap/orientation/permission flow.

## Prerequisites

Before running the app, make sure you have:

- **Flutter SDK** (stable channel)
- **Android Studio** (latest stable)
- **Flutter and Dart plugins** installed in Android Studio
- **Android SDK** installed and configured
- At least one **Android emulator** or a physical Android/iOS device

## Run in Android Studio

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd GPS_Camera
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   flutter run
   ```

## Validation commands

```bash
flutter doctor -v
flutter analyze
flutter test
```

## Permissions used

The app requests runtime permissions for:

- Camera
- Microphone (video recording)
- Location (GPS metadata)
- Photos/media storage

Platform declarations are configured in:

- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## Google Maps API key — where to add it

> Current implementation uses **OpenStreetMap (`flutter_map`)**, so a Google Maps API key is **not required**.

If you later switch to Google Maps (`google_maps_flutter`), add keys here:

### Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Inside `<application>`, add:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_GOOGLE_MAPS_API_KEY" />
```

### iOS

1. Open `ios/Runner/AppDelegate.swift`
2. Import Google Maps and provide the key in `application(_:didFinishLaunchingWithOptions:)`:

```swift
import GoogleMaps

GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
```

Also ensure the iOS key is enabled for **Maps SDK for iOS** in Google Cloud Console.

## Troubleshooting

### Flutter/Dart not found

If `flutter` or `dart` are not recognized, install Flutter and add it to your PATH.

### Camera or location not working

- Ensure permissions are granted in OS settings.
- Test on a real device for best GPS/camera behavior.

### Build issues

```bash
flutter clean
flutter pub get
```

Then retry.

## Helpful documentation

- Flutter install: https://docs.flutter.dev/get-started/install
- Android Studio: https://developer.android.com/studio
- Flutter packages: https://pub.dev/
