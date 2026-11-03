import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/sema_colors.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/pressable.dart';

/// Up to [AppConfig.maxPhotos] photos: already-uploaded ones (by URL) plus
/// newly picked files.
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.existingUrls,
    required this.files,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveFile,
  });

  final List<String> existingUrls;
  final List<XFile> files;
  final ValueChanged<List<XFile>> onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveFile;

  int get _count => existingUrls.length + files.length;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(SolarIconsOutline.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(SolarIconsOutline.gallery),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final remaining = AppConfig.maxPhotos - _count;
    try {
      final picked = source == ImageSource.camera
          ? [?await picker.pickImage(source: source, maxWidth: 2400)]
          : await picker.pickMultiImage(maxWidth: 2400, limit: remaining);
      if (picked.isNotEmpty) onAdd(picked.take(remaining).toList());
    } catch (_) {
      if (context.mounted) {
        Toast.show(context, 'Could not open the ${source.name}. Check app permissions.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tiles = <Widget>[
      for (final (i, url) in existingUrls.indexed)
        _Tile(image: CachedNetworkImageProvider(url), onRemove: () => onRemoveExisting(i)),
      for (final (i, f) in files.indexed)
        _Tile(image: FileImage(File(f.path)), onRemove: () => onRemoveFile(i)),
    ];

    if (_count == 0) {
      return InkWell(
        onTap: () => _pick(context),
        borderRadius: Radii.card,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: Radii.card,
            border: Border.all(color: c.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(SolarIconsOutline.cameraAdd, color: c.brandText, size: 30),
              const SizedBox(height: Space.xs),
              Text('Add photos', style: context.text.titleSmall),
              Text(
                'Up to ${AppConfig.maxPhotos} · helps staff find and fix it faster',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...tiles.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: Space.xs),
              child: t.animate().scale(curve: Curves.easeOutBack),
            ),
          ),
          if (_count < AppConfig.maxPhotos)
            InkWell(
              onTap: () => _pick(context),
              borderRadius: Radii.card,
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: Radii.card,
                  border: Border.all(color: c.line),
                ),
                child: Icon(SolarIconsOutline.addCircle, color: c.brandText),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.image, required this.onRemove});

  final ImageProvider image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: Radii.card,
          child: Image(image: image, width: 96, height: 96, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Pressable(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: c.text.withValues(alpha: 0.7), shape: BoxShape.circle),
              child: Icon(SolarIconsOutline.closeCircle, size: 16, color: c.page),
            ),
          ),
        ),
      ],
    );
  }
}
