# GPS Camera (Flutter)

This is a standard Flutter app scaffold configured for Android, iOS, web, desktop, and tests.

## Current project health (Android Studio + Flutter)

From a repository/config perspective, this project is structurally correct for Android Studio:

- Flutter package metadata and Dart SDK constraint are present.
- Android Gradle setup uses modern Kotlin DSL files.
- Android entrypoint (`MainActivity`) and manifest are valid.

> Note: In this environment, `flutter` is not installed, so I cannot execute `flutter doctor`, `flutter pub get`, or an APK build here. See the verification commands below and run them on your machine.

---

## Run this project in Android Studio (recommended flow)

### 1) Install tooling

- Install **Android Studio** (latest stable).
- Install **Flutter SDK** (stable channel).
- In Android Studio, install plugins:
  - **Flutter**
  - **Dart**

### 2) Clone and open

```bash
git clone <your-repo-url>
cd GPS_Camera
```

Then open the folder in Android Studio.

### 3) Verify SDK paths

Create/update `android/local.properties` (this file is local-only, do not commit):

```properties
flutter.sdk=/absolute/path/to/flutter
sdk.dir=/absolute/path/to/Android/Sdk
```

### 4) Run baseline checks (terminal in project root)

```bash
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

If Gradle sync fails in Android Studio, run:

```bash
cd android
./gradlew --version
./gradlew tasks
```

### 5) Run from Android Studio

- Start an Android emulator (or connect a device with USB debugging).
- Select the device in the toolbar.
- Click **Run**.

---

## Android notes

- The project currently uses placeholder application id/namespace `com.example.gps_camera`.
  - Change this before publishing.
- Release signing is currently set to debug signing for convenience.
  - Configure proper release signing before Play Store deployment.

---

## Troubleshooting quick fixes

### A) `flutter.sdk not set in local.properties`

Add `flutter.sdk=...` to `android/local.properties`.

### B) Gradle sync issues

- Confirm Android SDK and Java are installed.
- Make sure your Flutter SDK is on stable and up-to-date:

```bash
flutter channel stable
flutter upgrade
```

### C) Stale build cache

```bash
flutter clean
flutter pub get
```

---

## Useful docs

- Flutter install: https://docs.flutter.dev/get-started/install
- Flutter + Android setup: https://docs.flutter.dev/get-started/install/windows/mobile
- Android Studio: https://developer.android.com/studio
