import 'package:flutter/foundation.dart';

import '../../../models/app_photo.dart';
import '../../../services/app_photo_store.dart';

class GalleryController extends ChangeNotifier {
  GalleryController({AppPhotoStore photoStore = const AppPhotoStore()})
      : _photoStore = photoStore;

  final AppPhotoStore _photoStore;
  final Set<String> _selectedIds = <String>{};
  List<AppPhoto> _photos = const [];
  bool _loading = false;

  List<AppPhoto> get photos => List.unmodifiable(_photos);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isLoading => _loading;
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _photos = await _photoStore.loadPhotos();
    _selectedIds.clear();
    _loading = false;
    notifyListeners();
  }

  void toggleSelection(AppPhoto photo) {
    if (!_selectedIds.add(photo.id)) {
      _selectedIds.remove(photo.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  List<AppPhoto> selectedPhotos() =>
      _photos.where((photo) => _selectedIds.contains(photo.id)).toList(growable: false);
}
