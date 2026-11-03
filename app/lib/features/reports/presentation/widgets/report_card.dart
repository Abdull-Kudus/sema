import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/sema_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/report.dart';
import '../../domain/report_enums.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SemaCard(
      onTap: () => context.push('/report/${report.id}'),
      padding: const EdgeInsets.all(Space.sm),
      child: Row(
        children: [
          _Thumb(report: report),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium,
                      ),
                    ),
                    if (report.priority == ReportPriority.high) ...[
                      const SizedBox(width: Space.xxs),
                      Icon(SolarIconsBold.fire, size: 16, color: c.crimson.fg),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(SolarIconsOutline.mapPoint, size: 14, color: c.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.fullLocation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    StatusPill(report.status, dense: true),
                    const Spacer(),
                    if (report.upvotes > 0) ...[
                      Icon(SolarIconsBold.usersGroupRounded, size: 14, color: c.muted),
                      const SizedBox(width: 3),
                      Text('${report.upvotes}', style: context.text.labelSmall),
                      const SizedBox(width: Space.xs),
                    ],
                    Text(Formatters.relative(report.createdAt), style: context.text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    if (report.photoUrls.isEmpty) return CategoryBadge(report.category, size: size);
    return Hero(
      tag: 'photo-${report.id}-0',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: CachedNetworkImage(
          imageUrl: report.photoUrls.first,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => ColoredBox(color: context.colors.skeleton),
          errorWidget: (_, _, _) => CategoryBadge(report.category, size: size),
        ),
      ),
    );
  }
}

/// Placeholder list shown while reports load.
class ReportListSkeleton extends StatelessWidget {
  const ReportListSkeleton({super.key, this.count = 4, this.shrinkWrap = false});

  final int count;
  final bool shrinkWrap;

  static final _placeholder = Report(
    id: 'skeleton',
    title: 'Broken projector in room',
    description: '',
    category: ReportCategory.facilities,
    priority: ReportPriority.medium,
    status: ReportStatus.submitted,
    location: 'Main Building · Room 204',
    reporterId: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(baseColor: context.colors.skeleton, highlightColor: context.colors.panel),
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: IgnorePointer(child: ReportCard(report: _placeholder)),
            ),
        ],
      ),
    );
  }
}
