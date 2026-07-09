import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

/// Year-end clearance: requirement checklist + PDF download/share.
class ClearanceScreen extends ConsumerStatefulWidget {
  const ClearanceScreen({super.key});

  @override
  ConsumerState<ClearanceScreen> createState() => _ClearanceScreenState();
}

class _ClearanceScreenState extends ConsumerState<ClearanceScreen> {
  bool _downloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBytes('/student/portal/clearance/pdf');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Year_End_Clearance.pdf');
      await file.writeAsBytes(response.data!);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Year-End Clearance',
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clearanceProvider);
    final clearance = data.value?['clearance'] as Map<String, dynamic>?;

    return PortalSubScreen(
      title: 'Clearance',
      bottomBar: clearance != null
          ? Container(
              decoration: const BoxDecoration(
                  color: Colors.white, boxShadow: kNavShadow),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: GradientButton(
                    text: 'Download PDF',
                    icon: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 18),
                    isLoading: _downloading,
                    onPressed: _downloading ? null : _downloadPdf,
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(clearanceProvider),
        child: data.when(
          loading: () => const ShimmerList(count: 5, itemHeight: 72),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(clearanceProvider),
              ),
            ],
          ),
          data: (d) {
            final period = d['period'] as Map<String, dynamic>?;
            final clearance = d['clearance'] as Map<String, dynamic>?;

            if (period == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.verified_rounded,
                    headline: 'No clearance period yet',
                    subtext:
                        'The registrar has not opened a clearance period for this school year.',
                  ),
                ],
              );
            }

            if (clearance == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                children: [
                  EmptyState(
                    icon: Icons.hourglass_empty_rounded,
                    headline: 'Clearance not yet generated',
                    subtext:
                        '${period['title'] ?? 'The clearance period'} is set up, but your individual clearance has not been generated yet. Check back soon.',
                  ),
                ],
              );
            }

            final items = (clearance['items'] as List?) ?? const [];
            final done = items
                .where((i) => ['cleared', 'waived', 'not_applicable']
                    .contains((i as Map)['status']))
                .length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _SummaryCard(
                    period: period,
                    clearance: clearance,
                    done: done,
                    total: items.length),
                const SizedBox(height: 20),
                const SectionLabel('REQUIREMENTS'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 52),
                        _ItemTile(item: items[i] as Map<String, dynamic>),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> period;
  final Map<String, dynamic> clearance;
  final int done;
  final int total;

  const _SummaryCard(
      {required this.period,
      required this.clearance,
      required this.done,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3557), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x282563EB), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(period['title']?.toString() ?? 'Clearance',
                    style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
              ),
              PortalStatusChip.forStatus(
                  clearance['status']?.toString() ?? 'in_progress'),
            ],
          ),
          if (clearance['section_name'] != null) ...[
            const SizedBox(height: 2),
            Text(
                'Grade ${clearance['grade_level'] ?? '—'} — ${clearance['section_name']}',
                style: AppTextStyles.custom(fontSize: 12, color: Colors.white70)),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: progress >= 1 ? const Color(0xFF4ADE80) : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text('$done of $total requirements cleared',
              style: AppTextStyles.custom(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? 'pending';
    final isDone = ['cleared', 'waived', 'not_applicable'].contains(status);
    final isBlocked = ['hold', 'returned'].contains(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : isBlocked
                    ? Icons.error_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: isDone
                ? AppColors.success
                : isBlocked
                    ? Colors.red.shade600
                    : AppColors.textDisabled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['requirement_label']?.toString() ?? '—',
                    style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w600)),
                if (item['signed_by'] != null)
                  Text('Signed by ${item['signed_by']}',
                      style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary)),
                if ((item['blocker_summary']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item['blocker_summary'].toString(),
                        style: AppTextStyles.custom(fontSize: 11, color: Colors.red.shade700, height: 1.4)),
                  ),
                if ((item['remarks']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item['remarks'].toString(),
                        style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PortalStatusChip.forStatus(status),
        ],
      ),
    );
  }
}
