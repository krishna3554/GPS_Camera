import 'package:camera/camera.dart';

class CameraControllerProvider {
  const CameraControllerProvider();

  Future<List<CameraDescription>> available() => availableCameras();

  CameraController create({
    required CameraDescription camera,
    required ResolutionPreset resolutionPreset,
    bool enableAudio = false,
  }) {
    return CameraController(
      camera,
      resolutionPreset,
      enableAudio: enableAudio,
    );
  }
}
