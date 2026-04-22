import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/camera_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/map_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GPS Camera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/gallery',
          name: 'gallery',
          builder: (context, state) => const GalleryScreen(),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) =>
          DetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    final statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.photos,
    ].request();

    if (!mounted) {
      return;
    }

    final isCameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final isLocationGranted =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;
    final isPhotosGranted = statuses[Permission.photos]?.isGranted ?? false;

    if (isCameraGranted && isLocationGranted && isPhotosGranted) {
      context.goNamed('camera');
    } else {
      context.goNamed('settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _tabRoutes = ['/camera', '/gallery', '/map'];

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int currentIndex = _tabRoutes.indexWhere((route) {
      return location == route || location.startsWith('$route/');
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_camera), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: 'Gallery'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
        ],
        onDestinationSelected: (index) {
          context.go(_tabRoutes[index]);
        },
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Detail')),
      body: Center(child: Text('Photo id: $id')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Camera, location, and photo permissions are required to use all tabs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.goNamed('splash'),
              child: const Text('Retry permissions'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Open app settings'),
            ),
          ],
        ),
      ),
    );
  }
}
