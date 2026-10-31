import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/app_notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUserProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watch(uid);
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.read).length ?? 0,
);

class NotificationActions {
  NotificationActions(this._ref);

  final Ref _ref;

  String? get _uid => _ref.read(currentUserProvider).value?.uid;

  Future<void> markRead(AppNotification n) async {
    final uid = _uid;
    if (uid == null || n.read) return;
    await _ref.read(notificationRepositoryProvider).markRead(uid, n.id);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    final unread = _ref.read(notificationsProvider).value?.where((n) => !n.read).map((n) => n.id);
    if (uid == null || unread == null || unread.isEmpty) return;
    await _ref.read(notificationRepositoryProvider).markAllRead(uid, unread);
  }

  Future<void> remove(AppNotification n) async {
    final uid = _uid;
    if (uid == null) return;
    await _ref.read(notificationRepositoryProvider).remove(uid, n.id);
  }
}

final notificationActionsProvider = Provider(NotificationActions.new);
