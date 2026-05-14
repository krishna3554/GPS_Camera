import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/widgets/location_stamp_card.dart';
import '../../../models/captured_media.dart';
import '../../../models/location_info.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.permissionsGranted = true});

  final bool permissionsGranted;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _loading = true;
  bool _cameraError = false;
  bool _hasCameraPermission = false;
  bool _isPhotoMode = true;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;
  int _cameraIndex = 0;
  double _zoom = 1.0;
  double _baseZoom = 1.0;
  LocationInfo? _locationInfo;
  StreamSubscription<LocationInfo?>? _locationSub;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  late final AnimationController _captureAnim;
  bool _flashOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1,
      value: 1,
    );
    _hasCameraPermission = widget.permissionsGranted;
    _checkCameraPermissionAndInit();
  }

  Future<void> _checkCameraPermissionAndInit({bool request = false}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final granted = request
        ? await AppPermissionHandler.checkAndRequestCamera()
        : await AppPermissionHandler.hasCameraPermission();

    if (!mounted) return;
    if (!granted) {
      setState(() {
        _hasCameraPermission = false;
        _cameraError = false;
        _loading = false;
      });
      return;
    }

    setState(() => _hasCameraPermission = true);
    await _init();
  }

  Future<void> _requestCameraPermission() async {
    await _checkCameraPermissionAndInit(request: true);
    if (!mounted || _hasCameraPermission) return;

    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
    }
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _cameraError = false;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _cameraError = true;
          _loading = false;
        });
        return;
      }
      await _initController();
      _locationSub?.cancel();
      _locationSub = LocationUtils.locationStream().listen((value) {
        if (!mounted) return;
        setState(() => _locationInfo = value);
      });
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted') {
        if (!mounted) return;
        setState(() {
          _hasCameraPermission = false;
          _cameraError = false;
        });
      } else {
        await Future<void>.delayed(const Duration(seconds: 1));
        try {
          await _initController();
        } catch (_) {
          if (mounted) setState(() => _cameraError = true);
        }
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(seconds: 1));
      try {
        await _initController();
      } catch (_) {
        if (mounted) setState(() => _cameraError = true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initController() async {
    _controller?.dispose();
    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);
    _zoom = 1.0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRecording) {
      _stopRecording();
    } else if (state == AppLifecycleState.resumed) {
      _checkCameraPermissionAndInit();
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _captureAnim.reverse();
      await _captureAnim.forward();
      if (_isPhotoMode) {
        setState(() => _flashOverlay = true);
        Future<void>.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _flashOverlay = false);
        });
        final file = await _controller!.takePicture();
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          AppConstants.routeResult,
          arguments: ResultScreenArgs(
            filePath: file.path,
            locationInfo: _locationInfo ??
                const LocationInfo(
                  address: 'Location unavailable',
                  date: '',
                  time: '',
                  latitude: 0,
                  longitude: 0,
                ),
            type: MediaType.photo,
          ),
        );
      } else {
        if (_isRecording) {
          await _stopRecording();
        } else {
          await _startRecording();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<void> _startRecording() async {
    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final file = await _controller!.stopVideoRecording();
    if (!mounted) return;
    setState(() => _isRecording = false);
    Navigator.pushNamed(
      context,
      AppConstants.routeResult,
      arguments: ResultScreenArgs(
        filePath: file.path,
        locationInfo: _locationInfo ??
            const LocationInfo(
              address: 'Location unavailable',
              date: '',
              time: '',
              latitude: 0,
              longitude: 0,
            ),
        type: MediaType.video,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _locationSub?.cancel();
    _controller?.dispose();
    _captureAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCameraPermission) {
      return _PermissionUI(onGrant: _requestCameraPermission);
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_cameraError) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.camera_alt_outlined, size: 56),
            const SizedBox(height: 8),
            const Text('Camera not available on this device'),
            FilledButton(onPressed: _init, child: const Text('Restart Camera')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onScaleStart: (_) => _baseZoom = _zoom,
            onScaleUpdate: (details) async {
              final next = (_baseZoom * details.scale).clamp(0.5, 8.0);
              _zoom = next;
              await _controller!.setZoomLevel(next);
            },
            child: CameraPreview(_controller!),
          ),
          if (_flashOverlay)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOverlay ? 0.7 : 0,
                duration: const Duration(milliseconds: 100),
                child: Container(color: Colors.white),
              ),
            ),
          _buildTopToolbar(),
          if (_isRecording)
            Positioned(
              top: 80,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _recordDuration.toString().split('.').first,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 180,
            child: Center(
              child: LocationStampCard(
                locationInfo: _locationInfo,
                cardWidth: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 40,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cameraOverlay,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              color: Colors.white,
              onPressed: () async {
                final modes = [FlashMode.off, FlashMode.always, FlashMode.auto];
                _flashMode = modes[(modes.indexOf(_flashMode) + 1) % modes.length];
                await _controller?.setFlashMode(_flashMode);
                if (mounted) setState(() {});
              },
              icon: Icon(
                _flashMode == FlashMode.off
                    ? Icons.flash_off
                    : _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : Icons.flash_on,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: () async {
                _cameraIndex = (_cameraIndex + 1) % _cameras.length;
                await _initController();
                if (mounted) setState(() {});
              },
            ),
            const Icon(Icons.camera_alt, color: Colors.white),
            IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.white),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(
                  height: 150,
                  child: Center(child: Text('Template selection coming soon')),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.workspace_premium, color: Colors.amber),
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Go Premium'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AppConstants.zoomLevels.entries.map((entry) {
              final selected = _zoom == entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () async {
                      _zoom = entry.value;
                      await _controller?.setZoomLevel(entry.value);
                      if (mounted) setState(() {});
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(entry.key,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _nav('Gallery', Icons.photo_library,
                        onTap: () => Navigator.pushNamed(
                            context, AppConstants.routeGallery)),
                    _nav('Locations', Icons.place, onTap: () => Navigator.pushNamed(context, AppConstants.routeLocations)),
                    ScaleTransition(
                      scale: _captureAnim,
                      child: GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _isRecording
                                    ? Colors.red
                                    : AppColors.primary,
                                width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _nav('Template', Icons.dashboard),
                    _nav('Settings', Icons.settings),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _mode('PHOTO', _isPhotoMode, () => setState(() => _isPhotoMode = true)),
                    const SizedBox(width: 18),
                    _mode('VIDEO', !_isPhotoMode,
                        () => setState(() => _isPhotoMode = false)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mode(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? AppColors.primary : Colors.black54,
                    fontWeight: FontWeight.bold)),
            if (selected)
              Container(width: 32, height: 2, color: AppColors.primary)
            else
              const SizedBox(height: 2),
          ],
        ),
      );

  Widget _nav(String label, IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.black54, size: 20),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))
          ],
        ),
      );
}

class _PermissionUI extends StatelessWidget {
  const _PermissionUI({required this.onGrant});
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, size: 56),
          const SizedBox(height: 10),
          const Text('Camera permission required'),
          const SizedBox(height: 10),
          FilledButton(onPressed: onGrant, child: const Text('Grant Permission')),
        ]),
      ),
    );
  }
}
