import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/widgets/location_stamp_card.dart';
import '../../../models/captured_media.dart';
import '../../../models/app_settings.dart';
import '../../../models/geo_photo_model.dart';
import '../../../models/location_info.dart';
import '../../../services/location_service.dart';
import '../../../services/error_reporter.dart';
import '../../../services/settings_service.dart';

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
  AppSettings _settings = const AppSettings();
  FlashMode _flashMode = FlashMode.off;
  int _cameraIndex = 0;
  double _zoom = 1.0;
  double _baseZoom = 1.0;
  LocationInfo? _locationInfo;
  StreamSubscription<LocationInfo?>? _locationSub;
  late final AnimationController _captureAnim;
  bool _flashOverlay = false;
  bool _isGeoProcessing = false;
  String? _cameraErrorMessage;
  final LocationService _locationService = const LocationService();
  final SettingsService _settingsService = const SettingsService();

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
    _loadSettingsAndInit();
  }

  Future<void> _loadSettingsAndInit() async {
    try {
      _settings = await _settingsService.load();
      await _checkCameraPermissionAndInit();
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Failed to load camera settings or initialize camera.',
      );
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _cameraErrorMessage = 'Camera could not start. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _checkCameraPermissionAndInit({bool request = false}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final bool granted;
    try {
      granted = request
          ? await AppPermissionHandler.checkAndRequestCamera()
          : await AppPermissionHandler.hasCameraPermission();
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Failed to check camera permission.',
      );
      if (!mounted) return;
      setState(() {
        _hasCameraPermission = false;
        _cameraErrorMessage = 'Unable to check camera permission.';
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    if (!granted) {
      setState(() {
        _hasCameraPermission = false;
        _cameraError = false;
        _cameraErrorMessage = null;
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

    try {
      final status = await Permission.camera.status;
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Failed to open app settings for camera permission.',
      );
    }
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _cameraError = false;
      _cameraErrorMessage = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _cameraError = true;
          _cameraErrorMessage = 'No camera was found on this device.';
          _loading = false;
        });
        return;
      }
      await _initController();
      _locationSub?.cancel();
      _locationSub = LocationUtils.locationStream().listen(
        (value) {
          if (!mounted) return;
          setState(() => _locationInfo = value);
        },
        onError: (Object error, StackTrace stackTrace) {
          ErrorReporter.recordError(
            error,
            stackTrace,
            reason: 'Live location stream failed.',
          );
        },
      );
    } on CameraException catch (e, stackTrace) {
      await ErrorReporter.recordError(
        e,
        stackTrace,
        reason: 'Camera initialization failed.',
      );
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted') {
        if (!mounted) return;
        setState(() {
          _hasCameraPermission = false;
          _cameraError = false;
          _cameraErrorMessage = 'Camera permission is required to take photos.';
        });
      } else {
        await Future<void>.delayed(const Duration(seconds: 1));
        try {
          await _initController();
        } catch (retryError, retryStackTrace) {
          await ErrorReporter.recordError(
            retryError,
            retryStackTrace,
            reason: 'Camera initialization retry failed.',
          );
          if (mounted) {
            setState(() {
              _cameraError = true;
              _cameraErrorMessage = 'Camera is temporarily unavailable.';
            });
          }
        }
      }
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Unexpected camera initialization failure.',
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      try {
        await _initController();
      } catch (retryError, retryStackTrace) {
        await ErrorReporter.recordError(
          retryError,
          retryStackTrace,
          reason: 'Unexpected camera initialization retry failure.',
        );
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMessage = 'Camera is temporarily unavailable.';
          });
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initController() async {
    _controller?.dispose();
    _controller = CameraController(
      _cameras[_cameraIndex],
      _settings.resolutionPreset,
      enableAudio: false,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);
    _zoom = 1.0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettingsAndInit();
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _captureAnim.reverse();
      await _captureAnim.forward();
      setState(() => _flashOverlay = true);
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _flashOverlay = false);
      });
      final file = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _isGeoProcessing = true);

      final locationInfo = await _resolveCaptureLocation();
      if (!mounted) return;
      setState(() => _isGeoProcessing = false);

      Navigator.pushNamed(
        context,
        AppConstants.routeResult,
        arguments: ResultScreenArgs(
          filePath: file.path,
          locationInfo: locationInfo,
          type: MediaType.photo,
        ),
      );
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Photo capture failed.',
      );
      if (!mounted) return;
      setState(() => _isGeoProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Capture failed: $error')));
    }
  }

  Future<LocationInfo> _resolveCaptureLocation() async {
    try {
      final geoPhoto = await _locationService.getCurrentGeoPhoto();
      return _locationInfoFromGeoPhoto(geoPhoto);
    } on LocationServiceException catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Location service returned a handled capture error.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error, stackTrace) {
      await ErrorReporter.recordError(
        error,
        stackTrace,
        reason: 'Unexpected location resolution failure.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location unavailable: $error')),
        );
      }
    }

    return _locationInfo ??
        const LocationInfo(
          address: 'Location unavailable',
          date: '',
          time: '',
          latitude: 0,
          longitude: 0,
        );
  }

  LocationInfo _locationInfoFromGeoPhoto(GeoPhotoModel geoPhoto) {
    return LocationInfo(
      address: geoPhoto.address,
      date: _formatCaptureDate(geoPhoto.capturedAt.toLocal()),
      time: geoPhoto.formattedDateTime.split('  ').last,
      latitude: geoPhoto.latitude,
      longitude: geoPhoto.longitude,
      placeName: geoPhoto.placeName,
      locality: geoPhoto.locality,
      administrativeArea: geoPhoto.administrativeArea,
      country: geoPhoto.country,
      postalCode: geoPhoto.postalCode,
      altitude: geoPhoto.altitude,
      speedMetersPerSecond: geoPhoto.speedMetersPerSecond,
      heading: geoPhoto.heading,
      accuracy: geoPhoto.accuracy,
    );
  }

  String _formatCaptureDate(DateTime dateTime) {
    final pattern = _settings.dateFormat == 'YYYY-MM-DD' ? 'yyyy-MM-dd' : 'dd/MM/yyyy';
    return DateFormat(pattern).format(dateTime);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            Text(_cameraErrorMessage ?? 'Camera not available on this device'),
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
            child: _CameraPreviewCover(controller: _controller!),
          ),
          if (_flashOverlay)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOverlay ? 0.7 : 0,
                duration: const Duration(milliseconds: 100),
                child: Container(color: Colors.white),
              ),
            ),
          if (_isGeoProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Getting GPS and address...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildTopToolbar(),
          Positioned(
            left: 0,
            right: 0,
            top: _settings.overlayPosition == 'top' ? 110 : null,
            bottom: _settings.overlayPosition == 'bottom' ? 180 : null,
            child: Center(
              child: LocationStampCard(
                locationInfo: _locationInfo,
                settings: _settings,
                cardWidth: MediaQuery.of(context).size.width * 0.9,
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
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
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
                                color: AppColors.primary,
                                width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _nav('Account', Icons.person_rounded,
                        onTap: () => Navigator.pushNamed(context, AppConstants.routeAccount)),
                    _nav('Templates', Icons.dashboard_customize,
                        onTap: _showTemplateSheet),
                  ],
                ),
                const SizedBox(height: 4),
                Center(child: _mode('PHOTO', true, () {}))
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showTemplateSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overlay Templates',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...OverlayTemplateIds.all.map(
                (id) => _TemplateChoiceTile(
                  id: id,
                  selected: _settings.overlayTemplate == id,
                  locationInfo: _locationInfo,
                  settings: _settings.copyWith(overlayTemplate: id),
                  onTap: () => Navigator.pop(context, id),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected == _settings.overlayTemplate) return;
    final next = _settings.copyWith(overlayTemplate: selected);
    await _settingsService.save(next);
    if (!mounted) return;
    setState(() => _settings = next);
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


class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    final portraitPreviewSize = Size(previewSize.height, previewSize.width);
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: portraitPreviewSize.width,
            height: portraitPreviewSize.height,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _TemplateChoiceTile extends StatelessWidget {
  const _TemplateChoiceTile({
    required this.id,
    required this.selected,
    required this.locationInfo,
    required this.settings,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final LocationInfo? locationInfo;
  final AppSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewInfo = locationInfo ??
        const LocationInfo(
          address: '123 Market Street, Springfield',
          date: '05/16/2026',
          time: '10:24 AM',
          latitude: 37.42199,
          longitude: -122.08406,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.primary : Colors.white12, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 122,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [Color(0xFF263238), Color(0xFF101010)]),
                ),
                child: LocationStampCard(
                  locationInfo: previewInfo,
                  settings: settings,
                  compactPreview: true,
                  cardWidth: 112,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(OverlayTemplateIds.label(id), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      OverlayTemplateIds.description(id),
                      style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
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
