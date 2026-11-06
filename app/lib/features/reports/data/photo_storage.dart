import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

class UploadedPhoto {
  const UploadedPhoto(this.url, this.path);

  final String url;
  final String path;
}

/// Compresses photos and stores them in Supabase Storage.
///
/// Every request carries the user's Firebase ID token (see main.dart), and the
/// bucket's policies only let a verified ALU user write under their own uid
/// (backend/supabase/storage.sql).
class PhotoStorage {
  PhotoStorage(this._storage);

  final SupabaseStorageClient _storage;

  StorageFileApi get _bucket => _storage.from(AppConfig.photoBucket);

  Future<UploadedPhoto> uploadReportPhoto({
    required String uid,
    required String reportId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _upload('reports/$uid/$reportId/$name', file, onProgress: onProgress);
  }

  /// Avatars keep one path, so the URL carries a version to bypass image caches.
  Future<UploadedPhoto> uploadAvatar({required String uid, required XFile file}) async {
    final photo = await _upload('avatars/$uid/avatar.jpg', file, overwrite: true);
    return UploadedPhoto('${photo.url}?v=${DateTime.now().millisecondsSinceEpoch}', photo.path);
  }

  Future<UploadedPhoto> _upload(
    String path,
    XFile file, {
    bool overwrite = false,
    void Function(double progress)? onProgress,
  }) async {
    final bytes =
        await FlutterImageCompress.compressWithFile(
          file.path,
          minWidth: AppConfig.photoMaxWidth,
          minHeight: AppConfig.photoMaxWidth,
          quality: AppConfig.photoQuality,
        ) ??
        await file.readAsBytes();

    // Supabase uploads in one request, so progress moves per photo, not per byte.
    onProgress?.call(0);
    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/jpeg', upsert: overwrite),
    );
    onProgress?.call(1);
    return UploadedPhoto(_bucket.getPublicUrl(path), path);
  }

  /// Removing a file that is already gone is not an error in Supabase.
  Future<void> deleteAll(Iterable<String> paths) async {
    final list = paths.toList();
    if (list.isEmpty) return;
    await _bucket.remove(list);
  }
}
