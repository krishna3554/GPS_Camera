import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_photo.dart';
import 'connectivity_service.dart';
import 'error_reporter.dart';

class BackupProgress {
  const BackupProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  double get value => total == 0 ? 0 : completed / total;
}

/// Offline-first backup coordinator.
///
/// Upload integration can be added in [_uploadSinglePhoto]. The queueing,
/// persistence, connectivity detection, and retry plumbing are ready now so
/// callers can safely request backups while offline.
class BackupService {
  BackupService({ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? ConnectivityService();

  static const _queueKey = 'pending_backup_photos';

  final ConnectivityService _connectivityService;

  Future<void> queuePhotoForBackup(AppPhoto photo) async {
    final queued = await pendingPhotos();
    queued.removeWhere((item) => item.id == photo.id || item.filePath == photo.filePath);
    queued.add(photo);
    await _saveQueue(queued);

    if (await _connectivityService.isOnline) {
      await retryPendingBackups(userId: 'local-device');
    }
  }

  Future<List<AppPhoto>> pendingPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_queueKey) ?? const <String>[];
    final photos = <AppPhoto>[];
    for (final raw in rawItems) {
      try {
        final photo = AppPhoto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (await File(photo.filePath).exists()) photos.add(photo);
      } catch (error, stackTrace) {
        await ErrorReporter.recordError(
          error,
          stackTrace,
          reason: 'Failed to decode queued backup photo.',
        );
      }
    }
    return photos;
  }

  Stream<BackupProgress> uploadPhotosForUser({
    required String userId,
    required List<AppPhoto> photos,
  }) async* {
    if (!await _connectivityService.isOnline) {
      for (final photo in photos) {
        await queuePhotoForBackup(photo);
      }
      yield BackupProgress(completed: 0, total: photos.length);
      return;
    }

    for (var index = 0; index < photos.length; index++) {
      try {
        await _uploadSinglePhoto(userId: userId, photo: photos[index]);
      } catch (error, stackTrace) {
        await queuePhotoForBackup(photos[index]);
        await ErrorReporter.recordError(
          error,
          stackTrace,
          reason: 'Photo backup failed and was queued for retry.',
        );
      }
      yield BackupProgress(completed: index + 1, total: photos.length);
    }
  }

  Future<void> retryPendingBackups({required String userId}) async {
    if (!await _connectivityService.isOnline) return;

    final queued = await pendingPhotos();
    if (queued.isEmpty) return;

    final remaining = <AppPhoto>[];
    for (final photo in queued) {
      try {
        await _uploadSinglePhoto(userId: userId, photo: photo);
      } catch (error, stackTrace) {
        remaining.add(photo);
        await ErrorReporter.recordError(
          error,
          stackTrace,
          reason: 'Queued backup retry failed.',
        );
      }
    }
    await _saveQueue(remaining);
  }

  StreamSubscription<bool> startAutoRetry({required String userId}) {
    return _connectivityService.onlineChanges.listen((online) async {
      if (!online) return;
      try {
        await retryPendingBackups(userId: userId);
      } catch (error, stackTrace) {
        await ErrorReporter.recordError(
          error,
          stackTrace,
          reason: 'Automatic backup retry failed.',
        );
      }
    });
  }

  Future<void> _uploadSinglePhoto({
    required String userId,
    required AppPhoto photo,
  }) async {
    // Firebase Storage integration point: upload file to users/{uid}/photos/.
    if (!await File(photo.filePath).exists()) {
      throw FileSystemException('Photo file is missing.', photo.filePath);
    }
    await Future<void>.delayed(const Duration(milliseconds: 75));
  }

  Future<void> _saveQueue(List<AppPhoto> photos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queueKey,
      photos.map((photo) => jsonEncode(photo.toJson())).toList(),
    );
  }
}
