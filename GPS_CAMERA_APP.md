# 📍 GPS Camera App — Claude Code Implementation Plan

> **Flutter · 100% Free APIs · Beginner-Friendly**
> Built with OpenStreetMap, SQLite, geolocator — no paid APIs required.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Full Feature List](#2-full-feature-list)
3. [Tech Stack](#3-tech-stack)
4. [App Architecture](#4-app-architecture)
5. [Folder Structure](#5-folder-structure)
6. [pubspec.yaml — All Dependencies](#6-pubspecyaml--all-dependencies)
7. [Permissions Setup](#7-permissions-setup)
8. [Database Schema](#8-database-schema)
9. [Phase-Wise Roadmap](#9-phase-wise-roadmap)
10. [Phase Details & Claude Code Prompts](#10-phase-details--claude-code-prompts)
11. [Key Code Patterns](#11-key-code-patterns)
12. [Common Pitfalls](#12-common-pitfalls)
13. [Testing Checklist](#13-testing-checklist)
14. [Build & Deploy](#14-build--deploy)

---

## 1. Project Overview

A cross-platform mobile app (Android + iOS) that lets users take photos automatically tagged with GPS coordinates, reverse-geocoded addresses, altitude, and compass heading. All geotagged photos are stored locally and visualised on an interactive map.

### MVP Goals
- [ ] Take photos with live GPS overlay on viewfinder
- [ ] Auto-tag photos with coordinates + address
- [ ] Store all photos + metadata in SQLite
- [ ] View photos in a gallery grid
- [ ] View all photo locations on an OpenStreetMap map
- [ ] Photo detail screen with full metadata

### V2 Goals
- [ ] Trip / route recording with polyline
- [ ] Photo sharing with a custom location card
- [ ] Search photos by city / landmark (Nominatim API — free)
- [ ] Export to GeoJSON / KML
- [ ] Heatmap of frequently photographed spots
- [ ] Compass + AR overlay on camera viewfinder
- [ ] Optional Firebase cloud backup (free Spark plan)
- [ ] Offline map tile caching
- [ ] Dark mode
- [ ] Batch photo delete with multi-select
- [ ] Photo notes / captions
- [ ] Custom marker icons per photo category (food, travel, nature…)
- [ ] Widget for home screen showing last captured location

---

## 2. Full Feature List

### Core Camera Features
| Feature | Priority | Notes |
|---|---|---|
| Camera viewfinder with live GPS overlay | MVP | Show lat/lng + accuracy badge |
| Single tap to capture | MVP | |
| Front / rear camera toggle | MVP | |
| Flash toggle (auto / on / off) | MVP | |
| Pinch-to-zoom | MVP | |
| Timer capture (3s / 5s / 10s) | V2 | |
| Burst mode | V2 | |
| Photo resolution selector | V2 | |

### GPS & Location Features
| Feature | Priority | Notes |
|---|---|---|
| Get GPS fix before capture | MVP | Wait for accuracy < 20 m |
| Display coordinates on camera screen | MVP | |
| Reverse geocode to address | MVP | Uses OS geocoder, no API key |
| Altitude display | MVP | From GPS sensor |
| Compass heading at capture | MVP | `flutter_compass` |
| GPS accuracy indicator | MVP | Green / yellow / red badge |
| Accuracy threshold setting | V2 | User sets minimum accuracy |
| Speed display while moving | V2 | |
| Trip route recording | V2 | Save polyline to DB |

### Gallery Features
| Feature | Priority | Notes |
|---|---|---|
| Grid view of all geotagged photos | MVP | Sorted by newest first |
| Photo detail screen | MVP | Full image + all metadata |
| Long-press to delete | MVP | |
| Multi-select + batch delete | V2 | |
| Search by address / city | V2 | Filter photos locally |
| Filter by date range | V2 | |
| Photo captions / notes | V2 | Editable field in detail screen |
| Sort by distance from current location | V2 | |

### Map Features
| Feature | Priority | Notes |
|---|---|---|
| Show all photos as markers on OSM | MVP | |
| Tap marker → photo detail | MVP | |
| Cluster markers when zoomed out | V2 | `flutter_map_marker_cluster` |
| Heatmap layer | V2 | |
| Trip route polylines | V2 | |
| Full-screen map toggle | V2 | |
| Search map by place name (Nominatim) | V2 | Free OSM geocoder API |

### Export & Sharing
| Feature | Priority | Notes |
|---|---|---|
| Share photo with location card overlay | V2 | Custom card with coords + address |
| Export all metadata to GeoJSON | V2 | |
| Export to KML (Google Earth) | V2 | |
| Copy coordinates to clipboard | MVP | Tap coords on detail screen |

### Settings & UX
| Feature | Priority | Notes |
|---|---|---|
| Coordinate format (DMS / DD) | V2 | Decimal degrees or degrees-minutes-seconds |
| Unit system (metric / imperial) | V2 | |
| Save original + annotated copies | V2 | |
| App theme (light / dark / system) | V2 | |
| GPS accuracy threshold setting | V2 | |
| Auto-delete duplicates | V2 | |

---

## 3. Tech Stack

> Every item below is **free to use**.

| Layer | Technology | Package / Version | Why |
|---|---|---|---|
| **Framework** | Flutter 3.x (Dart) | SDK stable | Cross-platform |
| **State Mgmt** | Riverpod 2.x | `flutter_riverpod: ^2.5.1` | Scales better than Provider |
| **Camera** | camera plugin | `camera: ^0.11.0` | Official Flutter plugin |
| **GPS** | geolocator | `geolocator: ^12.0.0` | No API key, stream-based |
| **Geocoding** | geocoding | `geocoding: ^3.0.0` | Uses OS geocoder, offline |
| **Compass** | flutter_compass | `flutter_compass: ^0.3.0` | Magnetometer access |
| **Maps** | flutter_map | `flutter_map: ^7.0.0` | OSM tiles, 100% free |
| **Map Tiles** | OpenStreetMap | (URL template, no key) | Free forever |
| **Marker Cluster** | flutter_map_marker_cluster | `^1.3.1` | V2 — cluster dense markers |
| **Local DB** | sqflite | `sqflite: ^2.3.3` | SQLite, no server |
| **File Paths** | path_provider | `path_provider: ^2.1.3` | App document directories |
| **Gallery Save** | gal | `gal: ^1.1.0` | Modern gallery_saver replacement |
| **Permissions** | permission_handler | `permission_handler: ^11.3.1` | Runtime permissions |
| **EXIF** | exif | `exif: ^4.0.0` | Read/write EXIF metadata |
| **Image Utils** | image | `image: ^4.2.0` | Thumbnail generation, EXIF write |
| **Sharing** | share_plus | `share_plus: ^9.0.0` | V2 — share photos |
| **Routing** | go_router | `go_router: ^13.2.0` | Declarative navigation |
| **Notifications** | flutter_local_notifications | `^17.0.0` | On-device, no server |
| **Intl / Dates** | intl | `intl: ^0.19.0` | Date formatting |
| **Cloud (optional)** | Firebase Spark Plan | `firebase_core`, `cloud_firestore`, `firebase_storage` | Free tier, V2 only |

### Why OpenStreetMap (not Google Maps)?
- Google Maps requires a billing account + credit card. OSM does not.
- `flutter_map` + OSM tiles work with zero configuration and zero cost.
- Nominatim API (free OSM geocoder) handles place-name search.

---

## 4. App Architecture

```
┌─────────────────────────────────────────────┐
│                   UI Layer                   │
│  CameraScreen  GalleryScreen  MapScreen      │
│  DetailScreen  SettingsScreen TripScreen     │
└────────────────────┬────────────────────────┘
                     │ Riverpod Providers
┌────────────────────▼────────────────────────┐
│              Business Logic Layer            │
│  CameraService   LocationService            │
│  GeocodingService  DatabaseService          │
│  StorageService    TripService              │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│                 Data Layer                   │
│  SQLite (sqflite)   Device File System      │
│  Firebase (optional, V2)                    │
└─────────────────────────────────────────────┘
```

### State Management with Riverpod
```
providers/
  camera_provider.dart       — CameraController state
  location_provider.dart     — live GPS stream
  photos_provider.dart       — list of GeoPhotos from DB
  map_provider.dart          — map state (center, zoom)
  settings_provider.dart     — user preferences
  trip_provider.dart         — active trip recording (V2)
```

---

## 5. Folder Structure

```
gps_camera_app/
├── lib/
│   ├── main.dart                    # App entry, ProviderScope, GoRouter
│   ├── app.dart                     # MaterialApp.router, theme
│   ├── models/
│   │   ├── geo_photo.dart           # GeoPhoto data class
│   │   ├── location_data.dart       # LocationData snapshot
│   │   └── trip.dart                # Trip with polyline (V2)
│   ├── services/
│   │   ├── camera_service.dart      # init, capture, dispose
│   │   ├── location_service.dart    # GPS fix, stream, accuracy
│   │   ├── geocoding_service.dart   # reverse geocode, Nominatim (V2)
│   │   ├── database_service.dart    # SQLite CRUD
│   │   ├── storage_service.dart     # file save, gallery, thumbnails
│   │   └── firebase_service.dart    # optional cloud sync (V2)
│   ├── providers/
│   │   ├── camera_provider.dart
│   │   ├── location_provider.dart
│   │   ├── photos_provider.dart
│   │   ├── map_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── camera_screen.dart       # viewfinder + capture
│   │   ├── gallery_screen.dart      # grid of photos
│   │   ├── map_screen.dart          # OSM map with markers
│   │   ├── detail_screen.dart       # full photo + metadata
│   │   ├── settings_screen.dart     # app settings
│   │   └── splash_screen.dart       # permission init
│   ├── widgets/
│   │   ├── gps_overlay.dart         # lat/lng/accuracy badge
│   │   ├── compass_widget.dart      # compass ring overlay
│   │   ├── photo_card.dart          # gallery grid tile
│   │   ├── map_marker.dart          # custom photo marker
│   │   ├── location_card.dart       # share card (V2)
│   │   └── accuracy_badge.dart      # green/yellow/red accuracy
│   └── utils/
│       ├── constants.dart           # DB name, OSM URL, thresholds
│       ├── coord_formatter.dart     # DD ↔ DMS conversion
│       ├── exif_writer.dart         # write GPS to EXIF
│       └── geojson_exporter.dart    # export to GeoJSON (V2)
├── assets/
│   ├── icons/
│   │   └── app_icon.png
│   └── fonts/                       # optional custom fonts
├── test/
│   ├── unit/
│   │   ├── geo_photo_test.dart
│   │   ├── database_service_test.dart
│   │   └── coord_formatter_test.dart
│   └── widget/
│       ├── camera_screen_test.dart
│       └── gallery_screen_test.dart
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
└── pubspec.yaml
```

---

## 6. pubspec.yaml — All Dependencies

```yaml
name: gps_camera_app
description: GPS Camera — geotag photos with coordinates and maps
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Camera
  camera: ^0.11.0

  # GPS & location
  geolocator: ^12.0.0
  geocoding: ^3.0.0
  flutter_compass: ^0.3.0

  # Maps (OpenStreetMap — FREE, no key)
  flutter_map: ^7.0.0
  latlong2: ^0.9.1
  flutter_map_marker_cluster: ^1.3.1  # V2

  # Storage & files
  sqflite: ^2.3.3
  path_provider: ^2.1.3
  path: ^1.9.0
  gal: ^1.1.0

  # Image processing
  image: ^4.2.0
  exif: ^4.0.0

  # Permissions
  permission_handler: ^11.3.1

  # Navigation
  go_router: ^13.2.0

  # Sharing
  share_plus: ^9.0.0

  # Utilities
  intl: ^0.19.0
  uuid: ^4.4.0

  # UI
  flutter_local_notifications: ^17.0.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0                      # loading skeletons

  # Optional: Firebase (V2 only — comment out until needed)
  # firebase_core: ^2.31.0
  # firebase_auth: ^4.19.0
  # cloud_firestore: ^4.17.0
  # firebase_storage: ^11.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  mockito: ^5.4.4

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

---

## 7. Permissions Setup

### Android — `android/app/src/main/AndroidManifest.xml`

Add inside `<manifest>` tag, above `<application>`:

```xml
<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />

<!-- GPS -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Storage (Android < 13) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Storage (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Compass / sensors -->
<uses-feature android:name="android.hardware.sensor.compass" android:required="false" />
```

Also set `minSdkVersion` to 21 in `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

### iOS — `ios/Runner/Info.plist`

Add inside the root `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to take geotagged photos.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to tag photos with GPS coordinates.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app uses your location to tag photos with GPS coordinates.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app saves geotagged photos to your photo library.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app reads your photo library to display geotagged photos.</string>
```

---

## 8. Database Schema

### Table: `geo_photos`

```sql
CREATE TABLE geo_photos (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  image_path  TEXT    NOT NULL,
  thumb_path  TEXT,
  latitude    REAL    NOT NULL,
  longitude   REAL    NOT NULL,
  altitude    REAL,
  accuracy    REAL,
  heading     REAL,
  speed       REAL,
  address     TEXT,
  city        TEXT,
  country     TEXT,
  caption     TEXT,
  timestamp   TEXT    NOT NULL,  -- ISO 8601: 2026-04-21T14:30:00Z
  trip_id     INTEGER,           -- FK → trips.id (V2)
  is_synced   INTEGER DEFAULT 0, -- 0 = local only, 1 = synced to cloud (V2)
  created_at  TEXT    NOT NULL
);
```

### Table: `trips` (V2)

```sql
CREATE TABLE trips (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT,
  start_time  TEXT NOT NULL,
  end_time    TEXT,
  route_json  TEXT,              -- JSON array of {lat, lng, timestamp}
  distance_m  REAL,
  photo_count INTEGER DEFAULT 0
);
```

### GeoPhoto Dart Model

```dart
class GeoPhoto {
  final int? id;
  final String imagePath;
  final String? thumbPath;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final String? address;
  final String? city;
  final String? country;
  final String? caption;
  final DateTime timestamp;

  // Convenience getters
  String get formattedCoords =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get dmsCoords => CoordFormatter.toDMS(latitude, longitude);

  Map<String, dynamic> toMap() { ... }
  factory GeoPhoto.fromMap(Map<String, dynamic> map) { ... }
}
```

---

## 9. Phase-Wise Roadmap

| Phase | Name | Deliverables | Time |
|---|---|---|---|
| **1** | Setup | Flutter install, project scaffold, Git | Week 1 |
| **2** | Camera | Viewfinder, capture, save to gallery | Week 2 |
| **3** | GPS | Live coordinates, permission flow, accuracy | Week 3 |
| **4** | Geo-tag + DB | Combine capture+GPS, SQLite, gallery screen | Week 4–5 |
| **5** | Map View | OSM map, photo markers, tap to detail | Week 6 |
| **6** | UI Polish | Navigation, theme, loading states, errors | Week 7 |
| **7** | Trip Recording | Route polyline, trip detail, distance calc | Week 8 |
| **8** | Export & Share | GeoJSON export, share card, Nominatim search | Week 9 |
| **9** | Firebase Sync | Auth, Firestore metadata, Storage upload | Week 10 |
| **10** | Test & Deploy | Unit tests, APK build, Play Store (optional) | Week 11 |

---

## 10. Phase Details & Claude Code Prompts

> Use these prompts directly in Claude Code (`claude` CLI) to implement each phase.

---

### Phase 1 — Project Setup

**Manual steps (do these yourself):**
```bash
# Install Flutter SDK from flutter.dev (stable channel)
flutter doctor          # fix any issues
flutter create gps_camera_app
cd gps_camera_app
git init && git add . && git commit -m "initial scaffold"
```

**Claude Code prompt:**
```
Set up the base project structure for a Flutter GPS camera app.

1. Replace pubspec.yaml with the dependencies listed in the implementation plan
   (riverpod, camera, geolocator, geocoding, flutter_compass, flutter_map,
   sqflite, path_provider, gal, image, exif, permission_handler, go_router,
   share_plus, intl, uuid)

2. Create the full folder structure:
   lib/models/, lib/services/, lib/providers/, lib/screens/,
   lib/widgets/, lib/utils/

3. Create lib/utils/constants.dart with:
   - OSM tile URL template
   - DB name and version
   - GPS accuracy thresholds (high: <10m, medium: <50m, low: >50m)
   - App color palette

4. Create lib/app.dart with MaterialApp.router using go_router,
   with named routes for: splash, camera, gallery, map, detail, settings

5. Update lib/main.dart to wrap with ProviderScope and call runApp(const App())

Run flutter pub get after.
```

---

### Phase 2 — Camera Screen

**Claude Code prompt:**
```
Implement the camera screen for a Flutter GPS camera app using the camera package.

Create lib/services/camera_service.dart:
- Initialize best available back camera
- Method: Future<XFile?> capturePhoto()
- Method: void toggleFlash()
- Method: void toggleCamera() (front/back)
- Method: void setZoom(double level)
- Proper dispose() handling

Create lib/providers/camera_provider.dart using Riverpod:
- StateNotifierProvider for CameraController
- Handle initialization state and errors

Create lib/screens/camera_screen.dart:
- Full-screen CameraPreview
- Bottom bar: flash toggle, capture button (large circle), camera flip
- Top bar: back button, settings icon
- Pinch-to-zoom on the preview
- Show a loading spinner while camera initializes
- Handle permission denied state with a "Grant Permission" button

Create lib/utils/constants.dart with permission messages.

Add required permissions to AndroidManifest.xml and iOS Info.plist.
```

---

### Phase 3 — GPS & Location Layer

**Claude Code prompt:**
```
Add GPS location services to the Flutter GPS camera app.

Create lib/services/location_service.dart:
- Method: Future<LocationPermission> requestPermission()
- Method: Future<Position> getCurrentPosition() with LocationAccuracy.high
- Method: Stream<Position> watchPosition() with LocationAccuracy.medium
- Method: bool isGpsEnabled()
- Handle all error cases: permission denied, GPS disabled, timeout

Create lib/models/location_data.dart:
- Fields: latitude, longitude, accuracy, altitude, heading, speed, timestamp
- Factory: fromPosition(Position p)
- Getter: String accuracyLabel → "High" / "Medium" / "Low"
- Getter: Color accuracyColor → green / orange / red

Create lib/providers/location_provider.dart using Riverpod:
- StreamProvider<LocationData?> that wraps watchPosition()
- Handle errors with AsyncValue

Create lib/widgets/gps_overlay.dart:
- Semi-transparent card showing lat/lng (6 decimal places)
- Accuracy badge (colored dot + metres)
- Altitude in metres
- Animated pulsing dot when GPS is acquiring fix
- Tap to copy coordinates to clipboard

Create lib/widgets/accuracy_badge.dart:
- Green = accuracy < 10m, Orange = < 50m, Red = > 50m

Update camera_screen.dart to show the gps_overlay in the top-left of the viewfinder.
Disable the capture button until GPS accuracy is better than 50m.
```

---

### Phase 4 — Geo-tagging & SQLite Storage

**Claude Code prompt:**
```
Implement geo-tagging and local SQLite storage for the Flutter GPS camera app.

Create lib/models/geo_photo.dart:
- All fields from the schema: id, imagePath, thumbPath, latitude, longitude,
  altitude, accuracy, heading, address, city, country, caption, timestamp
- toMap() and fromMap() methods
- Getters: formattedCoords, dmsCoords, formattedDate

Create lib/services/database_service.dart:
- Singleton pattern
- initDB() creates geo_photos table (schema from the implementation plan)
- insert(GeoPhoto photo) → int id
- getAll() → List<GeoPhoto> ordered by timestamp DESC
- getById(int id) → GeoPhoto?
- update(GeoPhoto photo) → void
- delete(int id) → void
- search(String query) → List<GeoPhoto> (matches address or city)

Create lib/services/geocoding_service.dart:
- reverseGeocode(double lat, double lng) → Future<Map<String, String>>
  Returns: {address, city, country}
- Handle timeout and null results gracefully (return empty strings, never throw)

Create lib/services/storage_service.dart:
- savePhoto(XFile photo) → Future<String> (returns saved file path)
- generateThumbnail(String imagePath) → Future<String> (128x128 jpg)
- deletePhoto(String imagePath) → Future<void>
- Uses path_provider for app documents directory

Create lib/utils/exif_writer.dart:
- writeGPSToExif(String imagePath, double lat, double lng, double? altitude)
  Writes GPS IFD tags into JPEG EXIF using the image package

Update lib/services/camera_service.dart:
- captureAndTag(LocationData location) → Future<GeoPhoto?>
  1. Capture photo → XFile
  2. Save to storage
  3. Generate thumbnail
  4. Write GPS to EXIF
  5. Reverse geocode
  6. Insert into DB
  7. Save to device gallery via gal
  Returns the saved GeoPhoto or null on failure

Create lib/screens/gallery_screen.dart:
- Reads all photos from DatabaseService via Riverpod provider
- GridView.builder with 3-column layout
- Each cell shows thumbnail + city name overlay
- Long-press → confirmation dialog → delete
- Empty state: illustration + "Take your first photo!"
- Pull-to-refresh

Create lib/providers/photos_provider.dart:
- StateNotifierProvider<List<GeoPhoto>>
- Methods: loadAll(), addPhoto(GeoPhoto), deletePhoto(int id)
```

---

### Phase 5 — Map View (OpenStreetMap)

**Claude Code prompt:**
```
Implement the map view screen for the Flutter GPS camera app using flutter_map and OpenStreetMap.

Create lib/screens/map_screen.dart:
- FlutterMap with TileLayer using OSM URL: https://tile.openstreetmap.org/{z}/{x}/{y}.png
- MarkerLayer: one marker per GeoPhoto using photo thumbnail as marker icon
- MapController for programmatic navigation
- FAB: "My Location" button — animate camera to current GPS position
- Tapping a marker opens the photo detail screen
- Show a count badge: "X photos" in top bar
- Loading shimmer while photos load

Create lib/widgets/map_marker.dart:
- Circular thumbnail (40x40) with a white border and drop shadow
- Tapping calls onTap(GeoPhoto)
- Falls back to a pin icon if thumbnail not available

Add to map_screen.dart for V2 readiness:
- Placeholder method showHeatmap() — empty but wired to a settings toggle
- Placeholder method showTripRoutes() — empty

OSM tile URL (no API key needed): https://tile.openstreetmap.org/{z}/{x}/{y}.png

Add flutter_map and latlong2 to pubspec.yaml if not already present.
```

---

### Phase 6 — Detail Screen & Navigation

**Claude Code prompt:**
```
Implement the photo detail screen and app-wide navigation for the Flutter GPS camera app.

Create lib/screens/detail_screen.dart:
- Full-screen photo with pinch-to-zoom (InteractiveViewer)
- Bottom sheet with metadata:
  * Full address
  * Coordinates (tap to copy, toggle DD ↔ DMS format)
  * Altitude (metres)
  * Compass heading (N/NE/E/SE/S/SW/W/NW)
  * Date & time (formatted)
  * GPS accuracy
- Action buttons: Share (share_plus), Delete, Edit Caption
- Mini OSM map showing the photo's location (non-interactive, zoomed in)
- "View on Full Map" button

Create lib/utils/coord_formatter.dart:
- toDMS(double lat, double lng) → String like "18°31'12.4\"N 73°51'34.2\"E"
- toDD(double lat, double lng) → String like "18.520111, 73.859500"
- headingToCompass(double heading) → String like "NE" or "North-East"

Update navigation using go_router:
- /splash    → SplashScreen (permission init)
- /camera    → CameraScreen
- /gallery   → GalleryScreen
- /map       → MapScreen
- /detail/:id → DetailScreen (receives GeoPhoto id)
- /settings  → SettingsScreen

Create a bottom navigation bar with 3 tabs: Camera | Gallery | Map
Use a ScaffoldWithNavBar wrapper in go_router's ShellRoute.

Create lib/screens/splash_screen.dart:
- Request camera + location permissions on startup
- If granted → navigate to /camera
- If denied → show explanation + "Open Settings" button
```

---

### Phase 7 — Trip Recording (V2)

**Claude Code prompt:**
```
Add trip / route recording to the Flutter GPS camera app.

Create lib/models/trip.dart:
- Fields: id, name, startTime, endTime, routePoints (List<LatLng>), distanceMetres, photoCount
- Method: double calculateDistance() using Geolocator.distanceBetween across routePoints
- toMap() / fromMap()

Update lib/services/database_service.dart:
- Add trips table (schema from implementation plan)
- CRUD methods for Trip
- getPhotosForTrip(int tripId) → List<GeoPhoto>

Create lib/services/trip_service.dart:
- startTrip(String? name) → Trip
- recordPoint(Position position) — called every 5 seconds while trip active
- stopTrip() → Trip with final stats
- Uses a Timer.periodic for point recording
- Minimum distance filter: only add point if > 10m from last point (avoids GPS jitter)

Create lib/providers/trip_provider.dart:
- StateNotifier with states: idle, recording, stopped
- Exposes: activeTripId, liveRoutePoints, liveDistance

Update camera_screen.dart:
- If a trip is active, show a red recording indicator in the top bar
- Auto-associate captured photos with the active trip

Update map_screen.dart:
- Draw active trip route as a PolylineLayer in blue
- Draw completed trip routes in grey
- Show trip start/end markers

Create lib/screens/trip_detail_screen.dart:
- Map with the full route polyline
- Stats: duration, distance, photo count
- Grid of photos taken during the trip
```

---

### Phase 8 — Export, Share & Nominatim Search (V2)

**Claude Code prompt:**
```
Add export, sharing, and location search features to the Flutter GPS camera app.

Create lib/utils/geojson_exporter.dart:
- photosToGeoJSON(List<GeoPhoto> photos) → String (valid GeoJSON FeatureCollection)
- Each feature: Point geometry + properties (address, timestamp, imagePath)
- tripsToKML(List<Trip> trips) → String (valid KML for Google Earth)

Update lib/screens/detail_screen.dart:
- Share button: uses share_plus to share image file + text card:
  "📍 [address]\n🕐 [timestamp]\n📐 [coordinates]"

Create lib/services/geocoding_service.dart — add Nominatim search:
- searchPlace(String query) → Future<List<NominatimResult>>
  Uses: https://nominatim.openstreetmap.org/search?q=...&format=json
  Add User-Agent header (required by Nominatim usage policy)
  Rate limit: 1 request per second (add delay)

Create lib/widgets/search_bar_widget.dart for gallery and map screens:
- Text field with debounce (300ms)
- Searches locally by address/city first
- Falls back to Nominatim for place names
- Results list with tap-to-filter

Update lib/screens/settings_screen.dart:
- Export all photos as GeoJSON button
- Export trips as KML button
- Storage info: photo count + total size
- Clear all data (with confirmation dialog)
- Coordinate format preference (DD or DMS)
```

---

### Phase 9 — Firebase Cloud Sync (V2 — Optional)

**Claude Code prompt:**
```
Add optional Firebase cloud sync to the Flutter GPS camera app.
Firebase Spark Plan is free: 1GB Firestore + 5GB Storage.

Setup (do manually first):
1. Create project at console.firebase.google.com
2. Enable Email/Password Auth
3. Enable Cloud Firestore
4. Enable Firebase Storage
5. Run: flutterfire configure

Uncomment Firebase dependencies in pubspec.yaml and run flutter pub get.

Create lib/services/firebase_service.dart:
- signIn(email, password) / signOut() / createAccount(email, password)
- uploadPhoto(GeoPhoto photo) → Future<String> storageUrl
  Uploads to: photos/{userId}/{photoId}.jpg
  Only uploads if on WiFi (use connectivity_plus to check)
- syncMetadata(GeoPhoto photo) → void
  Writes to Firestore: users/{userId}/photos/{photoId}
- downloadUserPhotos() → Future<List<GeoPhoto>>
- isWifiConnected() → Future<bool>

Create lib/screens/auth_screen.dart:
- Email + password login form
- Sign up link
- "Skip" button (app works fully offline without account)

Update lib/screens/settings_screen.dart:
- Show login/logout state
- "Sync now" button (manual sync)
- Auto-sync toggle (WiFi only)
- Show sync status per photo in gallery (cloud icon if synced)

Update GeoPhoto model to include:
- firebaseUrl: String? (null = not synced)
- isSynced: bool

Firestore security rules (paste into Firebase console):
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/photos/{photoId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

### Phase 10 — Testing & Build

**Claude Code prompt:**
```
Write tests and prepare the Flutter GPS camera app for release.

Create test/unit/geo_photo_test.dart:
- Test toMap() and fromMap() round-trip
- Test formattedCoords getter
- Test dmsCoords getter with known values

Create test/unit/database_service_test.dart:
- Test insert and getAll
- Test delete removes the record
- Test search finds by city
- Use an in-memory sqflite database (sqflite_ffi_test)

Create test/unit/coord_formatter_test.dart:
- Test toDMS with Pune coordinates: 18.5204°N, 73.8567°E
- Test headingToCompass(45.0) = "NE"
- Test headingToCompass(180.0) = "S"

Create test/widget/gallery_screen_test.dart:
- Test empty state renders correctly
- Test grid renders photo cards when photos exist
- Mock DatabaseService

Run all tests:
  flutter test

Check for analysis issues:
  flutter analyze

Format code:
  dart format lib/ test/

Build release APK:
  flutter build apk --release --target-platform android-arm64

The APK will be at:
  build/app/outputs/flutter-apk/app-release.apk
```

---

## 11. Key Code Patterns

### Capture + Geo-tag in one action
```dart
Future<void> onCaptureTapped(
  CameraController controller,
  LocationData location,
) async {
  // 1. Take photo
  final XFile file = await controller.takePicture();

  // 2. Save + thumbnail
  final String savedPath = await StorageService().savePhoto(file);
  final String thumbPath = await StorageService().generateThumbnail(savedPath);

  // 3. Write GPS to EXIF
  await ExifWriter.writeGPSToExif(savedPath, location.latitude, location.longitude);

  // 4. Reverse geocode
  final geo = await GeocodingService().reverseGeocode(location.latitude, location.longitude);

  // 5. Save to DB
  final photo = GeoPhoto(
    imagePath: savedPath,
    thumbPath: thumbPath,
    latitude: location.latitude,
    longitude: location.longitude,
    altitude: location.altitude,
    accuracy: location.accuracy,
    heading: location.heading,
    address: geo['address'],
    city: geo['city'],
    country: geo['country'],
    timestamp: DateTime.now(),
  );
  await DatabaseService().insert(photo);

  // 6. Save to device gallery
  await Gal.putImage(savedPath);
}
```

### Live GPS stream with Riverpod
```dart
final locationStreamProvider = StreamProvider<LocationData?>((ref) async* {
  final hasPermission = await LocationService().requestPermission();
  if (!hasPermission) { yield null; return; }

  await for (final position in Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,   // battery-friendly for preview
      distanceFilter: 5,                   // only update if moved 5m
    ),
  )) {
    yield LocationData.fromPosition(position);
  }
});
```

### OpenStreetMap with photo markers
```dart
FlutterMap(
  mapController: mapController,
  options: MapOptions(
    initialCenter: LatLng(18.5204, 73.8567), // fallback: Pune
    initialZoom: 13,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.gps_camera_app',
    ),
    MarkerLayer(markers: photos.map((p) => _buildMarker(p)).toList()),
  ],
)
```

### GPS accuracy threshold before capture
```dart
bool get canCapture => 
    currentLocation != null && 
    (currentLocation!.accuracy ?? 999) < 50.0; // metres
```

---

## 12. Common Pitfalls

| Pitfall | Fix |
|---|---|
| GPS not working on emulator | Always test GPS on a real device |
| Camera black screen on hot reload | Call `controller.dispose()` then reinitialize |
| `CameraController` memory leak | Always dispose in `deactivate()` or `dispose()` |
| `geocoding` returns null | Wrap in try/catch, return empty string never throw |
| `gal` save fails silently | Check storage permission was granted for Android 13+ |
| OSM tiles slow on first load | Add `cachedTileProvider` from flutter_map_cached_tile |
| EXIF write corrupts image | Always write EXIF before saving to gallery |
| Riverpod provider not updating | Use `ref.invalidate()` after DB insert |
| Hard accuracy on first GPS fix | Wait 3–5 seconds after permission grant for GPS lock |
| Firebase Storage over quota | Set max file size in rules + compress images before upload |

---

## 13. Testing Checklist

### Functional
- [ ] Take photo — thumbnail appears in gallery
- [ ] GPS overlay updates live on camera screen
- [ ] Accuracy badge turns green when GPS lock is good
- [ ] Capture button disabled when accuracy > 50m
- [ ] Photo appears as marker on map at correct location
- [ ] Tap marker → opens detail screen for that photo
- [ ] Coordinates copy to clipboard on tap
- [ ] Delete photo — removed from gallery and map
- [ ] App reopened — all photos still present (SQLite persisted)

### Permission edge cases
- [ ] Deny camera permission → show "Grant Permission" UI
- [ ] Deny location permission → show explanation + settings link
- [ ] GPS turned off → show "Enable GPS" snackbar
- [ ] Revoke permissions mid-session → graceful error, no crash

### Device testing
- [ ] Test on real Android device (GPS is accurate)
- [ ] Test indoor (poor GPS) → accuracy badge shows red
- [ ] Test with no internet (geocoding may fail) → no crash
- [ ] Test with full storage → graceful error message

---

## 14. Build & Deploy

### Debug APK (for sharing directly)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/my-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias my-key

# Build
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires Mac + Xcode)
```bash
flutter build ipa --release
# Distribute via TestFlight for free beta testing
```

### Cost to publish
| Platform | Cost |
|---|---|
| Share APK via Drive / WhatsApp | Free |
| Google Play Store | $25 one-time registration |
| Apple App Store | $99/year |
| TestFlight (iOS beta) | Free |

---

## Cost Summary

Everything needed to build and run this app is **completely free**:

| Item | Cost |
|---|---|
| Flutter + Dart SDK | Free |
| All pub.dev packages | Free (open source) |
| OpenStreetMap tiles | Free, no key |
| Nominatim geocoding | Free (OSM project) |
| Device OS geocoder | Free (no API key) |
| SQLite (sqflite) | Free, on-device |
| Firebase Spark Plan | Free (1GB DB + 5GB Storage) |
| GitHub (version control) | Free |
| Android APK distribution | Free |
| **Total** | **₹0** |

---

*GPS Camera App — Implementation Plan | Flutter | April 2026*
