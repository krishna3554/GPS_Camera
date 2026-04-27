class AppConstants {
  static const String routeCamera = '/camera';
  static const String routeGallery = '/gallery';
  static const String routeDetail = '/detail';
  static const String routeResult = '/result';
  static const String routeLocations = '/locations';

  static const int minZoom = 1;
  static const int maxZoom = 8;
  static const int defaultZoomIndex = 1;

  static const Map<String, double> zoomLevels = {
    '0.5x': 0.5,
    '1x': 1.0,
    '2x': 2.0,
  };
}
