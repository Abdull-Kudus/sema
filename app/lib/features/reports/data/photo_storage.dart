import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/config/app_config.dart';

class UploadedPhoto {
  const UploadedPhoto(this.url, this.path);

  final String url;
  final String path;
}

/// Compresses and uploads photos to Firebase Storage.
class PhotoStorage {
  PhotoStorage(this._storage);

  final FirebaseStorage _storage;

  Future<UploadedPhoto> uploadReportPhoto({
    required String uid,
    required String reportId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _upload('reports/$uid/$reportId/$name', file, onProgress);
  }

  Future<UploadedPhoto> uploadAvatar({required String uid, required XFile file}) =>
      _upload('avatars/$uid/avatar.jpg', file, null);

  Future<UploadedPhoto> _upload(String path, XFile file, void Function(double progress)? onProgress) async {
    final bytes =
        await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: AppConfig.photoMaxWidth,
          minHeight: AppConfig.photoMaxWidth,
          quality: AppConfig.photoQuality,
        ) ??
        await file.readAsBytes();

    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return UploadedPhoto(await ref.getDownloadURL(), path);
  }

  Future<void> deleteAll(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await _storage.ref(path).delete();
      } on FirebaseException catch (e) {
        // Already gone is fine; anything else should surface.
        if (e.code != 'object-not-found') rethrow;
      }
    }
  }
}
