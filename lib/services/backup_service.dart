import '../models/app_photo.dart';

class BackupProgress {
  const BackupProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  double get value => total == 0 ? 0 : completed / total;
}

class BackupService {
  const BackupService();

  Stream<BackupProgress> uploadPhotosForUser({
    required String userId,
    required List<AppPhoto> photos,
  }) async* {
    // Firebase Storage integration point: upload each file to
    // users/{uid}/photos/ and yield progress as uploads complete.
    for (var index = 0; index <= photos.length; index++) {
      yield BackupProgress(completed: index, total: photos.length);
    }
  }
}
