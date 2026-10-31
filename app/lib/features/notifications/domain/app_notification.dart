import 'package:cloud_firestore/cloud_firestore.dart';

import '../../reports/domain/report_enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.reportId,
    required this.title,
    required this.body,
    required this.status,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String title;
  final String body;
  final ReportStatus status;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      reportId: d['reportId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      status: ReportStatus.parse(d['status'] as String?),
      read: d['read'] as bool? ?? false,
      createdAt: d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
