# GPS Camera (Flutter)

GPS Camera is a Flutter app for capturing photos with GPS metadata, viewing geotagged images in a gallery, and exploring photo locations on a map.

## Prerequisites

Before running the app in Android Studio, make sure you have:

- **Flutter SDK** (stable channel)
- **Android Studio** (latest stable)
- **Flutter and Dart plugins** installed in Android Studio
- **Android SDK** installed and configured
- At least one **Android emulator** or a physical Android device (USB debugging enabled)

## Run in Android Studio (step-by-step)

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd GPS_Camera
   ```

2. **Open the project in Android Studio**

   - Launch Android Studio.
   - Select **Open** and choose the `GPS_Camera` folder.

3. **Fetch dependencies**

   In Android Studio Terminal (or your system terminal at project root):

   ```bash
   flutter pub get
   ```

4. **Select an emulator or connected device**

   - Start an Android emulator from Device Manager, or connect a physical device.
   - Choose the target device from the device selector in the Android Studio toolbar.

5. **Create/select Run configuration**

   - Use the default Flutter run configuration (or create one via **Run > Edit Configurations**).
   - Ensure `lib/main.dart` is the entrypoint.

6. **Launch the app**
   - Click **Run** (green play button) in Android Studio.

## Terminal validation commands

Run these from the project root to validate setup and code health:

```bash
flutter doctor -v
flutter analyze
flutter test
flutter run
```

## Permissions notes (camera, location, media)

This app requires runtime permissions for core features:

- **Camera**: required to capture photos.
- **Location**: required to geotag photos with coordinates.
- **Media/Storage access**: required to save and display photos in gallery views.

If you deny a permission, related features may not work until access is re-enabled in system settings.

## Troubleshooting

### 1) `flutter doctor -v` shows missing components

- Install or update the missing SDK/tooling shown by `flutter doctor -v`.
- Re-run `flutter doctor -v` until all critical Android checks pass.

### 2) Device not listed in Android Studio

- Start an emulator from Device Manager.
- For physical devices, enable Developer Options and USB debugging.
- Confirm detection with:

  ```bash
  flutter devices
  ```

### 3) Build or sync failures

- Run:

  ```bash
  flutter clean
  flutter pub get
  ```

- Then retry **Run** in Android Studio.

### 4) Camera/location/media features not working

- Verify app permissions are granted in Android app settings.
- If permission was permanently denied, re-enable it manually in system settings.
- Test on both emulator and physical device when possible (camera/location behavior can vary).

## Helpful documentation

- Flutter install: https://docs.flutter.dev/get-started/install
- Android Studio: https://developer.android.com/studio
- Flutter Android setup: https://docs.flutter.dev/get-started/install/windows/mobile
