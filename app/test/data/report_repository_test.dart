import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sema/features/auth/domain/app_user.dart';
import 'package:sema/features/reports/data/report_repository.dart';
import 'package:sema/features/reports/domain/report.dart';
import 'package:sema/features/reports/domain/report_enums.dart';

void main() {
  late FakeFirebaseFirestore db;
  late ReportRepository repo;

  const student = AppUser(
    uid: 'stu',
    name: 'Amina Hassan',
    email: 'a.hassan@alustudent.com',
    role: UserRole.student,
  );
  const staff = AppUser(
    uid: 'stf',
    name: 'Facilities Desk',
    email: 'desk@alueducation.com',
    role: UserRole.staff,
  );

  const draft = ReportDraft(
    title: 'No water in Block B',
    description: 'There has been no water since this morning on floor 2.',
    category: ReportCategory.water,
    priority: ReportPriority.high,
    location: 'Student Residence',
    locationDetail: 'Block B',
  );

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ReportRepository(db);
  });

  Future<Report> create({bool anonymous = false}) async {
    final id = repo.newId();
    await repo.create(
      id: id,
      draft: anonymous
          ? const ReportDraft(
              title: 'No water in Block B',
              description: 'There has been no water since this morning on floor 2.',
              category: ReportCategory.water,
              priority: ReportPriority.high,
              location: 'Student Residence',
              isAnonymous: true,
            )
          : draft,
      reporter: student,
      photoUrls: const [],
      photoPaths: const [],
    );
    return (await repo.watchReport(id).first)!;
  }

  test('create stores the report and its first history entry', () async {
    final r = await create();
    expect(r.status, ReportStatus.submitted);
    expect(r.fullLocation, 'Student Residence · Block B');
    expect(r.reporterName, 'Amina Hassan');
    final updates = await repo.watchUpdates(r.id).first;
    expect(updates.single.status, ReportStatus.submitted);
  });

  test('anonymous reports do not store the reporter name', () async {
    final r = await create(anonymous: true);
    expect(r.reporterName, isNull);
    expect(r.displayReporter, 'Anonymous student');
    expect(r.reporterId, student.uid);
  });

  test('watchMine only returns the user’s reports', () async {
    await create();
    expect(await repo.watchMine('stu').first, hasLength(1));
    expect(await repo.watchMine('someone-else').first, isEmpty);
  });

  test('changeStatus updates, logs history and notifies the reporter', () async {
    final r = await create();
    await repo.changeStatus(report: r, status: ReportStatus.resolved, note: 'Pump replaced', staff: staff);

    final updated = (await repo.watchReport(r.id).first)!;
    expect(updated.status, ReportStatus.resolved);
    expect(updated.handledBy, 'Facilities Desk');
    expect(updated.resolvedAt, isNotNull);

    final history = await repo.watchUpdates(r.id).first;
    expect(history.map((u) => u.status), [ReportStatus.submitted, ReportStatus.resolved]);
    expect(history.last.note, 'Pump replaced');

    final inbox = await db.collection('users').doc('stu').collection('notifications').get();
    expect(inbox.docs.single.data()['reportId'], r.id);
    expect(inbox.docs.single.data()['read'], false);
  });

  test('upvotes toggle per user', () async {
    final r = await create();
    await repo.toggleUpvote(id: r.id, uid: 'peer', upvote: true);
    expect((await repo.watchReport(r.id).first)!.upvotes, 1);
    await repo.toggleUpvote(id: r.id, uid: 'peer', upvote: false);
    expect((await repo.watchReport(r.id).first)!.upvotes, 0);
  });

  test('delete removes the report and its history', () async {
    final r = await create();
    await repo.delete(r.id);
    expect(await repo.watchReport(r.id).first, isNull);
    expect(await repo.watchUpdates(r.id).first, isEmpty);
  });
}
