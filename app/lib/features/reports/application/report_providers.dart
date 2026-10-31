import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../domain/report.dart';
import '../domain/report_enums.dart';
import 'report_filter.dart';

final _uidProvider = Provider<String?>((ref) => ref.watch(currentUserProvider).value?.uid);

/// Every recent report on campus, live.
final campusReportsProvider = StreamProvider<List<Report>>((ref) {
  if (ref.watch(_uidProvider) == null) return Stream.value(const []);
  return ref.watch(reportRepositoryProvider).watchFeed();
});

/// The signed-in user's own reports, live.
final myReportsProvider = StreamProvider<List<Report>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(reportRepositoryProvider).watchMine(uid);
});

final reportProvider = StreamProvider.family<Report?, String>(
  (ref, id) => ref.watch(reportRepositoryProvider).watchReport(id),
);

final reportUpdatesProvider = StreamProvider.family<List<ReportUpdate>, String>(
  (ref, id) => ref.watch(reportRepositoryProvider).watchUpdates(id),
);

class ReportFilterController extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => const ReportFilter();

  void search(String q) => state = state.copyWith(query: q.trim());
  void status(ReportStatus? s) => state = state.copyWith(status: () => s);
  void scope(ReportScope s) => state = state.copyWith(scope: s);
  void sort(ReportSort s) => state = state.copyWith(sort: s);

  void toggleCategory(ReportCategory c) {
    final next = {...state.categories};
    next.contains(c) ? next.remove(c) : next.add(c);
    state = state.copyWith(categories: next);
  }

  void clear() => state = ReportFilter(scope: state.scope, sort: state.sort);
}

final reportFilterProvider = NotifierProvider<ReportFilterController, ReportFilter>(
  ReportFilterController.new,
);

/// The list currently in scope (campus or mine) before search/filter.
final scopedReportsProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final scope = ref.watch(reportFilterProvider.select((f) => f.scope));
  return scope == ReportScope.mine ? ref.watch(myReportsProvider) : ref.watch(campusReportsProvider);
});

final filteredReportsProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final filter = ref.watch(reportFilterProvider);
  return ref.watch(scopedReportsProvider).whenData(filter.apply);
});

final myStatsProvider = Provider<AsyncValue<ReportStats>>(
  (ref) => ref.watch(myReportsProvider).whenData(ReportStats.of),
);

final campusStatsProvider = Provider<AsyncValue<ReportStats>>(
  (ref) => ref.watch(campusReportsProvider).whenData(ReportStats.of),
);

/// Open reports ordered by urgency, for the staff "needs attention" queue.
final attentionQueueProvider = Provider<AsyncValue<List<Report>>>((ref) {
  return ref.watch(campusReportsProvider).whenData((reports) {
    final open = reports.where((r) => r.status.isOpen).toList()
      ..sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        if (p != 0) return p;
        final v = b.upvotes.compareTo(a.upvotes);
        return v != 0 ? v : a.createdAt.compareTo(b.createdAt);
      });
    return open;
  });
});

/// Open reports most students said "me too" to.
final trendingProvider = Provider<AsyncValue<List<Report>>>((ref) {
  return ref
      .watch(campusReportsProvider)
      .whenData(
        (reports) =>
            (reports.where((r) => r.status.isOpen && r.upvotes > 0).toList()
                  ..sort((a, b) => b.upvotes.compareTo(a.upvotes)))
                .take(5)
                .toList(),
      );
});

/// Progress of an in-flight submission: 0..1 while uploading photos.
class SubmitState {
  const SubmitState({this.busy = false, this.progress = 0, this.stage = ''});

  final bool busy;
  final double progress;
  final String stage;
}

/// Creates, edits and deletes reports, including their photos.
class ReportEditor extends Notifier<SubmitState> {
  @override
  SubmitState build() => const SubmitState();

  AppUser get _user {
    final user = ref.read(currentUserProvider).value;
    if (user == null) throw StateError('You need to be signed in.');
    return user;
  }

  /// Saves a new report (when [existing] is null) or updates one.
  /// [keptPhotos] are existing photos the user kept; [newPhotos] are picked files.
  /// Returns the report id.
  Future<String> save({
    required ReportDraft draft,
    required List<XFile> newPhotos,
    Report? existing,
    List<int> keptPhotos = const [],
  }) async {
    final user = _user;
    final reports = ref.read(reportRepositoryProvider);
    final storage = ref.read(photoStorageProvider);
    final id = existing?.id ?? reports.newId();

    state = const SubmitState(busy: true, stage: 'Preparing');
    final uploadedPaths = <String>[];
    try {
      final urls = [for (final i in keptPhotos) existing!.photoUrls[i]];
      final paths = [for (final i in keptPhotos) existing!.photoPaths[i]];

      for (var i = 0; i < newPhotos.length; i++) {
        state = SubmitState(
          busy: true,
          stage: 'Uploading photo ${i + 1} of ${newPhotos.length}',
          progress: i / newPhotos.length,
        );
        final photo = await storage.uploadReportPhoto(
          uid: user.uid,
          reportId: id,
          file: newPhotos[i],
          onProgress: (p) => state = SubmitState(
            busy: true,
            stage: 'Uploading photo ${i + 1} of ${newPhotos.length}',
            progress: (i + p) / newPhotos.length,
          ),
        );
        urls.add(photo.url);
        paths.add(photo.path);
        uploadedPaths.add(photo.path);
      }

      state = const SubmitState(busy: true, progress: 1, stage: 'Saving');
      if (existing == null) {
        await reports.create(id: id, draft: draft, reporter: user, photoUrls: urls, photoPaths: paths);
      } else {
        await reports.updateDetails(id: id, draft: draft, photoUrls: urls, photoPaths: paths);
        final removed = existing.photoPaths.where((p) => !paths.contains(p));
        await storage.deleteAll(removed);
      }
      return id;
    } catch (_) {
      // Don't leave orphaned uploads behind when saving fails.
      await storage.deleteAll(uploadedPaths).catchError((_) {});
      rethrow;
    } finally {
      state = const SubmitState();
    }
  }

  Future<void> delete(Report report) async {
    await ref.read(reportRepositoryProvider).delete(report.id);
    await ref.read(photoStorageProvider).deleteAll(report.photoPaths);
  }

  Future<void> toggleUpvote(Report report) {
    final uid = _user.uid;
    return ref
        .read(reportRepositoryProvider)
        .toggleUpvote(id: report.id, uid: uid, upvote: !report.upvotedBy(uid));
  }

  Future<void> changeStatus(Report report, ReportStatus status, String note) {
    final user = _user;
    if (!user.isStaff) throw StateError('Only campus staff can update a status.');
    return ref
        .read(reportRepositoryProvider)
        .changeStatus(report: report, status: status, note: note, staff: user);
  }
}

final reportEditorProvider = NotifierProvider<ReportEditor, SubmitState>(ReportEditor.new);
