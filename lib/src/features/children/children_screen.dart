import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../home/home_screen.dart' show BottomNav;
import '../home/home_provider.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── White header ──────────────────────────────────────────────
          AppHeader(
            greeting: 'Manage',
            name: 'My Children',
            subtitle: 'Linked student accounts',
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  tooltip: 'Link a child',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    backgroundColor: AppColors.accentBg,
                    shape: const CircleBorder(),
                    minimumSize: const Size(38, 38),
                    maximumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    await context.push('/children/link');
                    ref.invalidate(linkedStudentsProvider);
                  },
                ),
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: _ChildrenBody(
              onUnlink: (s) => _confirmUnlink(context, ref, s),
            ),
          ),
        ],
      ),
      floatingActionButton: _GradientFab(
        onTap: () async {
          await context.push('/children/link');
          ref.invalidate(linkedStudentsProvider);
        },
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  Future<void> _confirmUnlink(
      BuildContext context, WidgetRef ref, LinkedStudent student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unlink ${student.fullName}?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'You will stop receiving gate notifications for this student.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unlink',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/students/${student.barcode}/link');
      ref.invalidate(linkedStudentsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlink student.')),
        );
      }
    }
  }
}

// ── Gradient FAB ──────────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: AppGradients.button,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Link Child',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );
}

// ── Child card ────────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  final LinkedStudent student;
  final VoidCallback onUnlink;

  const _ChildCard({required this.student, required this.onUnlink});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4)),
            BoxShadow(
                color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            // Avatar with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.10),
                    AppColors.accentMid.withValues(alpha: 0.20),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (student.relationship != null) ...[
                        _Pill(
                          text: _capitalize(student.relationship!),
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text('ID: ${student.barcode}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            // Unlink button
            IconButton(
              icon: const Icon(Icons.link_off_rounded,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Unlink',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x0FFF4444),
                shape: const CircleBorder(),
              ),
              onPressed: onUnlink,
            ),
          ],
        ),
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

// ── Combined body ─────────────────────────────────────────────────────────────

class _ChildrenBody extends ConsumerWidget {
  final void Function(LinkedStudent) onUnlink;
  const _ChildrenBody({required this.onUnlink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(linkedStudentsProvider);
    final requests = ref.watch(linkRequestsProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(linkedStudentsProvider);
        ref.invalidate(linkRequestsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // ── Pending requests section ───────────────────────────────
          requests.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (reqs) {
              if (reqs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('PENDING CONFIRMATIONS'),
                  ...reqs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PendingRequestCard(
                          request: r,
                          onCancel: () async {
                            final client = ref.read(apiClientProvider);
                            await client.delete('/link-requests/${r.id}');
                            ref.invalidate(linkRequestsProvider);
                          },
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // ── Confirmed children section ─────────────────────────────
          students.when(
            loading: () => const Column(
              children: [
                ShimmerCard(height: 96),
                SizedBox(height: 12),
                ShimmerCard(height: 96),
              ],
            ),
            error: (_, _) => Center(
              child: Text('Could not load children',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary, fontSize: 14)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return requests.value?.isNotEmpty == true
                    ? const SizedBox.shrink()
                    : _EmptyState();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('LINKED CHILDREN'),
                  ...list.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChildCard(
                            student: s, onUnlink: () => onUnlink(s)),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Pending request card ──────────────────────────────────────────────────────

class _PendingRequestCard extends StatelessWidget {
  final LinkRequest request;
  final VoidCallback onCancel;

  const _PendingRequestCard({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFFDE68A))),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Awaiting Confirmation',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warningText)),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${request.maskedStudentId}  ·  ${_capitalize(request.relationship)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppColors.warningText),
                  ),
                  Text(
                    'Email sent to student — waiting for approval',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.warningText.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  color: AppColors.warningText, size: 20),
              tooltip: 'Cancel request',
              onPressed: onCancel,
            ),
          ],
        ),
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: AppColors.accentBg, shape: BoxShape.circle),
                child: const Icon(Icons.people_outline_rounded,
                    size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              Text('No children linked',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Link your child\'s ID card to receive\ngate attendance notifications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: GradientButton(
                  text: 'Link a Child',
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => context.push('/children/link'),
                ),
              ),
            ],
          ),
        ),
      );
}
