import 'package:cloud_firestore/cloud_firestore.dart';

import 'report_enums.dart';

DateTime _date(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.location,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    this.spot = '',
    this.locationDetail = '',
    this.photoUrls = const [],
    this.photoPaths = const [],
    this.reporterName,
    this.reporterPhotoUrl,
    this.isAnonymous = false,
    this.upvoterIds = const [],
    this.handledBy,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportPriority priority;
  final ReportStatus status;

  /// Campus area (a commons, the staff area…).
  final String location;

  /// Spot inside the area, such as a learning lab or the washrooms.
  final String spot;
  final String locationDetail;
  final List<String> photoUrls;
  final List<String> photoPaths;
  final String reporterId;
  final String? reporterName;
  final String? reporterPhotoUrl;
  final bool isAnonymous;
  final List<String> upvoterIds;
  final String? handledBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  /// Area, spot and free-text detail, e.g. "Social Commons · Washrooms · 2nd floor".
  String get fullLocation => [location, spot, locationDetail].where((p) => p.isNotEmpty).join(' · ');

  int get upvotes => upvoterIds.length;

  bool isOwnedBy(String? uid) => uid != null && uid == reporterId;

  bool upvotedBy(String? uid) => uid != null && upvoterIds.contains(uid);

  /// Owners can edit or withdraw a report until staff start working on it.
  bool canEditBy(String? uid) => isOwnedBy(uid) && status == ReportStatus.submitted;

  /// What other students see as the author.
  String get displayReporter => isAnonymous ? 'Anonymous student' : (reporterName ?? 'ALU student');

  Duration? get resolutionTime => resolvedAt?.difference(createdAt);

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Report(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: ReportCategory.parse(d['category'] as String?),
      priority: ReportPriority.parse(d['priority'] as String?),
      status: ReportStatus.parse(d['status'] as String?),
      location: d['location'] as String? ?? '',
      spot: d['spot'] as String? ?? '',
      locationDetail: d['locationDetail'] as String? ?? '',
      photoUrls: List<String>.from(d['photoUrls'] as List? ?? const []),
      photoPaths: List<String>.from(d['photoPaths'] as List? ?? const []),
      reporterId: d['reporterId'] as String? ?? '',
      reporterName: d['reporterName'] as String?,
      reporterPhotoUrl: d['reporterPhotoUrl'] as String?,
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      upvoterIds: List<String>.from(d['upvoterIds'] as List? ?? const []),
      handledBy: d['handledBy'] as String?,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// The editable part of a report, as filled in on the form.
class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.location,
    this.spot = '',
    this.locationDetail = '',
    this.isAnonymous = false,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final ReportPriority priority;
  final String location;
  final String spot;
  final String locationDetail;
  final bool isAnonymous;

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'category': category.name,
    'priority': priority.name,
    'location': location,
    'spot': spot,
    'locationDetail': locationDetail.trim(),
    'isAnonymous': isAnonymous,
  };
}

/// One entry in a report's status history.
class ReportUpdate {
  const ReportUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  final String id;
  final ReportStatus status;
  final String note;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;

  factory ReportUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ReportUpdate(
      id: doc.id,
      status: ReportStatus.parse(d['status'] as String?),
      note: d['note'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      authorRole: d['authorRole'] as String? ?? 'student',
      createdAt: _date(d['createdAt']),
    );
  }
}
