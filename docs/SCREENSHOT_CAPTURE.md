# UI Screenshot Capture Guide

This repository is being edited in an environment that does not include Flutter tooling or a browser screenshot runner.

Use one of the following local-device methods to capture real UI screenshots.

## Android (recommended)

1. Start the app:
   ```bash
   flutter pub get
   flutter run
   ```
2. Keep the app open on the screen you want.
3. Capture screenshot from your machine:
   ```bash
   adb exec-out screencap -p > camera_screen.png
   ```

## iOS Simulator

1. Start app in simulator:
   ```bash
   flutter pub get
   flutter run
   ```
2. Capture screenshot:
   ```bash
   xcrun simctl io booted screenshot camera_screen.png
   ```

## In-app screens to capture

- Camera tab (preview + capture button)
- Gallery tab (photo cards with share/delete)
- Map tab (OpenStreetMap markers)
