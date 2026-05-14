import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/index.dart';
import 'features/camera/screen/camera_screen.dart';
import 'features/detail/screen/detail_screen.dart';
import 'features/gallery/screen/gallery_screen.dart';
import 'features/result/screen/result_screen.dart';
import 'features/locations/screen/locations_screen.dart';
import 'features/settings/screen/settings_screen.dart';
import 'features/account/screen/account_screen.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';
import 'models/captured_media.dart';
import 'models/location_info.dart';

class DetailScreenArgs {
  const DetailScreenArgs({required this.assets, required this.initialIndex});

  final List<AssetEntity> assets;
  final int initialIndex;
}

class ResultScreenArgs {
  const ResultScreenArgs({
    required this.filePath,
    required this.locationInfo,
    required this.type,
  });

  final String filePath;
  final LocationInfo locationInfo;
  final MediaType type;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.permissionsGranted});

  final bool permissionsGranted;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
    const SettingsService().load().then((settings) {
      if (mounted) setState(() => _settings = settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Camera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings.themeMode,
      initialRoute: AppConstants.routeCamera,
      routes: {
        AppConstants.routeCamera: (_) =>
            CameraScreen(permissionsGranted: widget.permissionsGranted),
        AppConstants.routeGallery: (_) => const GalleryScreen(),
        AppConstants.routeLocations: (_) => const LocationsScreen(),
        AppConstants.routeSettings: (_) => const SettingsScreen(),
        AppConstants.routeAccount: (_) => const AccountScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppConstants.routeDetail) {
          final args = settings.arguments! as DetailScreenArgs;
          return MaterialPageRoute(
            builder: (_) => DetailScreen(
              assets: args.assets,
              initialIndex: args.initialIndex,
            ),
          );
        }

        if (settings.name == AppConstants.routeResult) {
          final args = settings.arguments! as ResultScreenArgs;
          return PageRouteBuilder(
            pageBuilder: (_, __, ___) => ResultScreen(
              filePath: args.filePath,
              locationInfo: args.locationInfo,
              type: args.type,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
          );
        }

        return null;
      },
    );
  }
}
