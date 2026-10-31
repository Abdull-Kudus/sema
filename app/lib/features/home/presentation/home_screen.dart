import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback.dart';
import '../../auth/application/auth_providers.dart';
import '../../reports/presentation/widgets/report_card.dart';
import 'staff_dashboard.dart';
import 'student_home.dart';

/// Shows the staff console or the student home depending on the user's role.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: user.when(
          loading: () => const Padding(padding: EdgeInsets.all(20), child: ReportListSkeleton(count: 5)),
          error: (e, _) => EmptyState.error(e, onRetry: () => ref.invalidate(currentUserProvider)),
          data: (u) {
            if (u == null) return const SizedBox.shrink();
            return u.isStaff ? StaffDashboard(user: u) : StudentHome(user: u);
          },
        ),
      ),
    );
  }
}
