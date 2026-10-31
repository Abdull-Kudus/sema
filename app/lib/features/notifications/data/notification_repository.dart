import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection(Collections.users).doc(uid).collection(Collections.notifications);

  Stream<List<AppNotification>> watch(String uid) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Future<void> markRead(String uid, String id) => _inbox(uid).doc(id).update({'read': true});

  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_inbox(uid).doc(id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> remove(String uid, String id) => _inbox(uid).doc(id).delete();
}
