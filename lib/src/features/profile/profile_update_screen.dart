import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'profile_update_provider.dart';

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  ConsumerState<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _originalValues = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String field, String? current) {
    _originalValues[field] = current ?? '';
    return _controllers.putIfAbsent(field, () => TextEditingController(text: current ?? ''));
  }

  Future<void> _submit() async {
    // Only send fields the student actually edited — sending every rendered
    // field (including ones left untouched/blank) would let approval wipe
    // out real data in columns the student never meant to change.
    final changes = <String, String>{};
    for (final entry in _controllers.entries) {
      final value = entry.value.text.trim();
      if (value != (_originalValues[entry.key] ?? '')) {
        changes[entry.key] = value;
      }
    }

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to submit.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).post(
        '/student/portal/profile-update',
        data: {'changes': changes},
      );
      ref.invalidate(profileUpdateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update request submitted for registrar review.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit your update. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(profileUpdateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Update My Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: ShimmerList(count: 4, itemHeight: 60),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Could not load your information.', style: AppTextStyles.body),
        ),
        data: (d) {
          final pending = d['pending'] as Map<String, dynamic>?;
          if (pending != null) {
            return _PendingBanner(pending: pending);
          }

          final current = (d['current'] as Map?)?.cast<String, dynamic>() ?? {};
          final editable = ((d['editable_fields'] as List?) ?? []).cast<String>().toSet();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text(
                'Changes are reviewed by the registrar before they take effect.',
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 20),
              for (final group in kFieldGroups.entries) ...[
                if (group.value.keys.any(editable.contains)) ...[
                  Text(group.key.toUpperCase(), style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  for (final field in group.value.entries)
                    if (editable.contains(field.key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: _controllerFor(field.key, current[field.key]?.toString()),
                          decoration: InputDecoration(labelText: field.value),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Submitting…' : 'Submit for Review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final Map<String, dynamic> pending;

  const _PendingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final changes = (pending['requested_changes'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Text(
            'Your update is awaiting registrar review.',
            style: AppTextStyles.bodySemibold.copyWith(color: AppColors.warningText),
          ),
        ),
        const SizedBox(height: 20),
        Text('SUBMITTED CHANGES', style: AppTextStyles.label),
        const SizedBox(height: 8),
        for (final entry in changes.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${entry.key}: ${entry.value}', style: AppTextStyles.body),
          ),
      ],
    );
  }
}
