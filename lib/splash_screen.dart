import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _validatePermissions();
  }

  Future<void> _validatePermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.photos,
    ].request();

    if (!mounted) {
      return;
    }

    final deniedPermission = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .cast<Permission?>()
        .firstWhere((permission) => permission != null, orElse: () => null);

    if (deniedPermission == null) {
      _goToHome();
      return;
    }

    await _showPermissionDialog();
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permissions required'),
          content: const Text(
            'Camera, location, and photo permissions are required to continue. '
            'Please enable them in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _validatePermissions();
              },
              child: const Text('Retry'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const _PermissionReadyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PermissionReadyScreen extends StatelessWidget {
  const _PermissionReadyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS Camera')),
      body: const Center(
        child: Text('Permissions granted. Ready to capture.'),
      ),
    );
  }
}
