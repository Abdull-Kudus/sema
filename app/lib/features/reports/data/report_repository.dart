import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../../auth/domain/app_user.dart';
import '../domain/report.dart';
import '../domain/report_enums.dart';

/// Firestore access for reports, their status history and the
/// notifications a status change sends to the reporter.
class ReportRepository {
  ReportRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports => _db.collection(Collections.reports);

  CollectionReference<Map<String, dynamic>> _updates(String reportId) =>
      _reports.doc(reportId).collection(Collections.updates);

  /// A new id, so photos can be uploaded under it before the report is saved.
  String newId() => _reports.doc().id;

  Stream<List<Report>> watchFeed() => _reports
      .orderBy('createdAt', descending: true)
      .limit(AppConfig.feedLimit)
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList());

  Stream<List<Report>> watchMine(String uid) => _reports
      .where('reporterId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Report.fromDoc).toList());

  Stream<Report?> watchReport(String id) =>
      _reports.doc(id).snapshots().map((d) => d.exists ? Report.fromDoc(d) : null);

  Stream<List<ReportUpdate>> watchUpdates(String id) =>
      _updates(id).orderBy('createdAt').snapshots().map((s) => s.docs.map(ReportUpdate.fromDoc).toList());

  Future<void> create({
    required String id,
    required ReportDraft draft,
    required AppUser reporter,
    required List<String> photoUrls,
    required List<String> photoPaths,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch()
      ..set(_reports.doc(id), {
        ...draft.toMap(),
        'status': ReportStatus.submitted.name,
        'photoUrls': photoUrls,
        'photoPaths': photoPaths,
        'reporterId': reporter.uid,
        // Anonymous reports keep the uid (for "my reports" and misuse review)
        // but never store the reporter's name or photo.
        'reporterName': draft.isAnonymous ? null : reporter.name,
        'reporterPhotoUrl': draft.isAnonymous ? null : reporter.photoUrl,
        'upvoterIds': <String>[],
        'createdAt': now,
        'updatedAt': now,
      })
      ..set(_updates(id).doc(), {
        'status': ReportStatus.submitted.name,
        'note': 'Report submitted',
        'authorId': reporter.uid,
        'authorName': draft.isAnonymous ? 'Anonymous student' : reporter.name,
        'authorRole': reporter.role.name,
        'createdAt': now,
      });
    await batch.commit();
  }

  Future<void> updateDetails({
    required String id,
    required ReportDraft draft,
    required List<String> photoUrls,
    required List<String> photoPaths,
  }) => _reports.doc(id).update({
    ...draft.toMap(),
    'photoUrls': photoUrls,
    'photoPaths': photoPaths,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> delete(String id) async {
    final updates = await _updates(id).get();
    final batch = _db.batch();
    for (final doc in updates.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_reports.doc(id));
    await batch.commit();
  }

  Future<void> toggleUpvote({required String id, required String uid, required bool upvote}) =>
      _reports.doc(id).update({
        'upvoterIds': upvote ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
      });

  /// Moves a report through the workflow, records the history entry and
  /// notifies the reporter, all in one atomic batch.
  Future<void> changeStatus({
    required Report report,
    required ReportStatus status,
    required String note,
    required AppUser staff,
  }) async {
    final now = FieldValue.serverTimestamp();
    final message = note.trim().isEmpty ? _defaultNote(status) : note.trim();
    final batch = _db.batch()
      ..update(_reports.doc(report.id), {
        'status': status.name,
        'updatedAt': now,
        'handledBy': staff.name,
        'resolvedAt': status == ReportStatus.resolved ? now : null,
      })
      ..set(_updates(report.id).doc(), {
        'status': status.name,
        'note': message,
        'authorId': staff.uid,
        'authorName': staff.name,
        'authorRole': staff.role.name,
        'createdAt': now,
      })
      ..set(
        _db.collection(Collections.users).doc(report.reporterId).collection(Collections.notifications).doc(),
        {
          'reportId': report.id,
          'title': '“${report.title}” is ${status.label.toLowerCase()}',
          'body': message,
          'status': status.name,
          'read': false,
          'createdAt': now,
        },
      );
    await batch.commit();
  }

  static String _defaultNote(ReportStatus s) => switch (s) {
    ReportStatus.acknowledged => 'Campus staff have seen your report.',
    ReportStatus.inProgress => 'A team is working on this issue.',
    ReportStatus.resolved => 'This issue has been fixed.',
    ReportStatus.rejected => 'This report was closed.',
    ReportStatus.submitted => 'Report submitted',
  };
}
