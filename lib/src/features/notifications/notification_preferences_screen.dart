import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class NotificationPrefs {
  final bool notifyPush;
  final bool notifyEmail;

  const NotificationPrefs({required this.notifyPush, required this.notifyEmail});

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        notifyPush: json['notify_push'] as bool,
        notifyEmail: json['notify_email'] as bool,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _notificationPrefsProvider =
    FutureProvider.autoDispose<NotificationPrefs>((ref) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/notification-preferences');
  return NotificationPrefs.fromJson(response.data as Map<String, dynamic>);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool? _notifyPush;
  bool? _notifyEmail;
  bool _saving = false;

  Future<void> _save() async {
    if (_notifyPush == null || _notifyEmail == null) return;
    setState(() => _saving = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/notification-preferences', data: {
        'notify_push': _notifyPush,
        'notify_email': _notifyEmail,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save preferences.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(_notificationPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            greeting: 'Configure',
            name: 'Notifications',
            subtitle: 'Control how you receive alerts',
          ),

          Expanded(
            child: prefsAsync.when(
              loading: () => const ShimmerList(count: 2, itemHeight: 76),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('Could not load settings',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary, fontSize: 14)),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(_notificationPrefsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (prefs) {
                _notifyPush  ??= prefs.notifyPush;
                _notifyEmail ??= prefs.notifyEmail;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Choose how you want to be alerted when your child enters or leaves campus.',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('ALERT METHODS'),

                    _PrefTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Instant alert on this device',
                      value: _notifyPush ?? prefs.notifyPush,
                      onChanged: (v) => setState(() => _notifyPush = v),
                    ),
                    const SizedBox(height: 10),
                    _PrefTile(
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Summary sent to your email',
                      value: _notifyEmail ?? prefs.notifyEmail,
                      onChanged: (v) => setState(() => _notifyEmail = v),
                    ),

                    const SizedBox(height: 32),

                    GradientButton(
                      text: 'Save Preferences',
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 3)),
          ],
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          title: Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          subtitle: Text(subtitle,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.textSecondary)),
          value: value,
          activeTrackColor: AppColors.accent,
          onChanged: onChanged,
        ),
      );
}
