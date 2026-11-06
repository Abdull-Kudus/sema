import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/reports/data/photo_storage.dart';
import '../features/reports/data/report_repository.dart';

/// Infrastructure providers. Tests override these with fakes.
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final storageProvider = Provider<SupabaseStorageClient>((_) => Supabase.instance.client.storage);

/// Overridden in main() once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);
final reportRepositoryProvider = Provider((ref) => ReportRepository(ref.watch(firestoreProvider)));
final photoStorageProvider = Provider((ref) => PhotoStorage(ref.watch(storageProvider)));
final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);
