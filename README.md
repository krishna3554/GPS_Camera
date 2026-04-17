# GPS Camera App (Flutter)

This project is a beginner-friendly GPS Camera app scaffold.

## Where to add files in a Flutter template project

If you already created a standard Flutter app (`flutter create gps_camera_app`), copy/merge files into these locations:

- `lib/main.dart` → app entry point and Provider setup.
- `lib/models/geo_photo.dart` → photo metadata model.
- `lib/services/` → camera/location/database services.
- `lib/providers/geo_photo_provider.dart` → app state and share/delete actions.
- `lib/screens/` → UI screens (`camera`, `gallery`, `map`, `home_shell`).
- `pubspec.yaml` → add dependencies used by the app.

## Recommended folder structure

```text
lib/
  main.dart
  models/
    geo_photo.dart
  providers/
    geo_photo_provider.dart
  screens/
    home_shell.dart
    camera_screen.dart
    gallery_screen.dart
    map_screen.dart
  services/
    database_service.dart
    location_service.dart
    photo_capture_service.dart
```

## Platform permissions you still must add

### Android
Add these permissions in `android/app/src/main/AndroidManifest.xml`:

- `android.permission.CAMERA`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.READ_MEDIA_IMAGES` (Android 13+)
- `android.permission.READ_EXTERNAL_STORAGE` (older Android)

### iOS
Add these keys in `ios/Runner/Info.plist`:

- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## Run

```bash
flutter pub get
flutter run
```

## Current implemented features

- Capture photo with camera preview.
- Save image directly to gallery.
- Read GPS coordinates and reverse-geocoded address.
- Persist metadata locally with SQLite.
- Show captured items in a gallery grid.
- Share image + location text from the gallery.
- Show saved photo points on OpenStreetMap.

## Screenshot

If you need real UI screenshots from a device/emulator, see `docs/SCREENSHOT_CAPTURE.md`.
