import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/sema_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/sema_logo.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../reports/application/report_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _changePhoto(AppUser user) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final photo = await ref.read(photoStorageProvider).uploadAvatar(uid: user.uid, file: file);
      await ref.read(authRepositoryProvider).updateProfile(user.uid, photoUrl: photo.url);
      if (mounted) Toast.show(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) Toast.show(context, 'Could not upload: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editName(AppUser user) async {
    final controller = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.length < 3 || name == user.name) return;
    await ref.read(authRepositoryProvider).updateProfile(user.uid, name: name);
  }

  Future<void> _signOut() async {
    final ok = await confirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in with your ALU email at any time.',
      confirmLabel: 'Sign out',
    );
    if (ok) await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = ref.watch(currentUserProvider).value;
    final stats = ref.watch(myStatsProvider).value;
    final mode = ref.watch(themeModeProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xxl),
          children: [
            Center(
              child: Stack(
                children: [
                  Hero(
                    tag: 'me-avatar',
                    child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 104, ring: true),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Pressable(
                      onTap: _uploading ? null : () => _changePhoto(user),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.page, width: 3),
                        ),
                        child: _uploading
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2, color: c.onBrand),
                              )
                            : Icon(SolarIconsBold.camera, size: 16, color: c.onBrand),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            Center(child: Text(user.name, style: context.text.headlineSmall)),
            Center(
              child: Text(user.email, style: context.text.bodyMedium?.copyWith(color: c.muted)),
            ),
            const SizedBox(height: Space.xs),
            Center(
              child: TonePill(
                label: user.role.label,
                tone: user.isStaff ? c.violet : c.sky,
                icon: user.isStaff ? SolarIconsBold.shieldUser : SolarIconsBold.squareAcademicCap,
              ),
            ),
            const SizedBox(height: Space.lg),
            SemaCard(
              child: Row(
                children: [
                  _Stat(value: stats?.total ?? 0, label: 'Reported'),
                  _divider(c),
                  _Stat(value: stats?.open ?? 0, label: 'Open'),
                  _divider(c),
                  _Stat(value: stats?.resolved ?? 0, label: 'Resolved'),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            Text('Appearance', style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(SolarIconsOutline.sun),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(SolarIconsOutline.moon),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(SolarIconsOutline.smartphone),
                    label: Text('Auto'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
            const SizedBox(height: Space.lg),
            Text('Account', style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            SemaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Row(icon: SolarIconsOutline.pen, label: 'Edit name', onTap: () => _editName(user)),
                  const Divider(indent: 56),
                  _Row(
                    icon: SolarIconsOutline.shieldCheck,
                    label: 'Privacy & community rules',
                    onTap: () => _showPrivacy(context),
                  ),
                  const Divider(indent: 56),
                  _Row(
                    icon: SolarIconsOutline.infoCircle,
                    label: 'About ${AppConfig.appName}',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: AppConfig.fullName,
                      applicationVersion: '1.0.0',
                      applicationIcon: const SemaMark(size: 44),
                      children: [Text('Built for the ${AppConfig.institution} community.')],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.crimson.fg,
                side: BorderSide(color: c.crimson.bg),
              ),
              icon: const Icon(SolarIconsOutline.logout_2),
              label: const Text('Sign out'),
            ),
          ].animate(interval: 30.ms).fadeIn(duration: Motion.medium).slideY(begin: 0.04),
        ),
      ),
    );
  }

  Widget _divider(SemaColors c) => Container(width: 1, height: 36, color: c.line);

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy & community rules', style: context.text.titleLarge),
              const SizedBox(height: Space.md),
              for (final (icon, text) in const [
                (SolarIconsBold.lockKeyhole, 'Only verified ALU accounts can open Sema.'),
                (
                  SolarIconsBold.incognito,
                  'Anonymous reports hide your name from other students. Staff can still follow up.',
                ),
                (SolarIconsBold.shieldUser, 'Only campus staff can change a report\'s status.'),
                (SolarIconsBold.danger, 'False or abusive reports may be closed and reviewed.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: context.colors.brand, size: 20),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(text, style: context.text.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedCount(value: value, style: context.text.headlineMedium),
        Text(label, style: context.text.bodySmall),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: context.colors.brand),
    title: Text(label, style: context.text.titleSmall),
    trailing: Icon(SolarIconsOutline.altArrowRight, color: context.colors.muted, size: 18),
  );
}
