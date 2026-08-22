import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/hero_header.dart';
import '../../shared/widgets/staggered_list.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HeroHeader(
            leading: HeroBackButton(
              onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            greeting: 'My Profile',
            name: user?.name ?? '—',
            subtitle: user?.email ?? '—',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.isStudent == true ? 'Student' : 'Parent',
                style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('ACCOUNT'),

                  if (user?.isStudent == true) ...[
                    StaggeredList(children: [
                      _MenuItem(
                        icon: Icons.badge_outlined,
                        label: 'Digital Student ID',
                        onTap: () => context.push('/student/id'),
                      ),
                      _MenuItem(
                        icon: Icons.edit_note_rounded,
                        label: 'Update My Information',
                        onTap: () => context.push('/student/profile-update'),
                      ),
                    ]),
                  ] else ...[
                    StaggeredList(children: [
                      _MenuItem(
                        icon: Icons.people_alt_outlined,
                        label: 'Manage Children',
                        onTap: () => context.push('/children'),
                      ),
                    ]),
                  ],
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notification Settings',
                    onTap: () => context.push('/notification-preferences'),
                  ),

                  const SizedBox(height: 16),
                  const SectionLabel('SESSION'),

                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: Colors.red.shade600,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text('Sign out?',
                              style: AppTextStyles.custom(fontWeight: FontWeight.w700)),
                          content: Text(
                            'You will need to sign in again to access your account.',
                            style: AppTextStyles.custom(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (color != null
                            ? color!
                            : AppColors.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: c),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySemibold.copyWith(color: c),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
