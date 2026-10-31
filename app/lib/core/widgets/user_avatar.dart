import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

import '../theme/sema_colors.dart';
import '../utils/formatters.dart';

/// The user's real profile photo (Google account or uploaded), falling back
/// to initials on a brand gradient. Anonymous reports show a mask icon.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 44,
    this.anonymous = false,
    this.ring = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final bool anonymous;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget fallback() => DecoratedBox(
      decoration: BoxDecoration(gradient: c.hero),
      child: Center(
        child: anonymous
            ? Icon(SolarIconsBold.incognito, color: c.onBrand, size: size * 0.5)
            : Text(
                Formatters.initials(name),
                style: context.text.titleMedium?.copyWith(color: c.onBrand, fontSize: size * 0.36),
              ),
      ),
    );

    final url = anonymous ? null : photoUrl;
    final image = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url == null || url.isEmpty
            ? fallback()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => ColoredBox(color: c.skeleton),
                errorWidget: (_, _, _) => fallback(),
              ),
      ),
    );

    if (!ring) return image;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.hero),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.page),
        child: image,
      ),
    );
  }
}
