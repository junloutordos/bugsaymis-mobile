import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../portal/portal_provider.dart';
import '../portal/portal_widgets.dart';
import 'admission_slips_provider.dart';

String _fmtDate(String raw) {
  try {
    return DateFormat('MMM d, y').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

/// Class Admission Slips — what needs a slip, my requests to the Registrar, and issued slips.
class AdmissionSlipsScreen extends ConsumerStatefulWidget {
  const AdmissionSlipsScreen({super.key});

  @override
  ConsumerState<AdmissionSlipsScreen> createState() => _AdmissionSlipsScreenState();
}

class _AdmissionSlipsScreenState extends ConsumerState<AdmissionSlipsScreen> {
  final Set<String> _selected = {};

  Future<void> _refresh() async {
    ref.invalidate(admissionSlipsProvider);
    ref.invalidate(portalDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(admissionSlipsProvider);

    return DefaultTabController(
      length: 3,
      child: PortalSubScreen(
        title: 'Admission Slips',
        subtitle: 'Request a slip for absences, tardiness or cut classes',
        body: data.when(
          loading: () => const ShimmerList(count: 4, itemHeight: 92),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(admissionSlipsProvider),
              ),
            ],
          ),
          data: (d) => Column(
            children: [
              const TabBar(
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.accent,
                tabs: [
                  Tab(text: 'Needs Slip'),
                  Tab(text: 'My Requests'),
                  Tab(text: 'Issued'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _NeedsSlipTab(
                      items: d.needsSlip,
                      selected: _selected,
                      onToggle: (key) => setState(() {
                        _selected.contains(key) ? _selected.remove(key) : _selected.add(key);
                      }),
                      onRefresh: _refresh,
                      onRequest: () async {
                        final keys = _selected.toList();
                        await context.push('/student/portal/admission-slips/request', extra: keys);
                        if (mounted) setState(_selected.clear);
                      },
                    ),
                    _RequestsTab(requests: d.requests, onRefresh: _refresh),
                    _IssuedTab(slips: d.slips, onRefresh: _refresh),
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

class _NeedsSlipTab extends StatelessWidget {
  final List<SlipItem> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Future<void> Function() onRefresh;
  final VoidCallback onRequest;

  const _NeedsSlipTab({
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onRefresh,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
          children: const [
            EmptyState(
              icon: Icons.task_alt_rounded,
              headline: 'You are all caught up',
              subtext: 'No attendance items need a Class Admission Slip.',
            ),
          ],
        ),
      );
    }

    final anyRequestable = items.any((i) => i.canRequest);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      children: [
                        if (item.canRequest)
                          Checkbox(
                            value: selected.contains(item.itemKey),
                            onChanged: (_) => onToggle(item.itemKey),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.hourglass_top_rounded, size: 20, color: AppColors.warning),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label, style: AppTextStyles.cardTitle),
                              const SizedBox(height: 2),
                              Text(_fmtDate(item.date), style: AppTextStyles.caption),
                              if (item.subjects.isNotEmpty)
                                Text(item.subjects.join(', '), style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (!item.canRequest)
                          Text('Request pending',
                              style: AppTextStyles.custom(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warningText)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (anyRequestable)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: selected.isEmpty ? null : onRequest,
                  child: const Text('Request Slip'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final List<SlipRequest> requests;
  final Future<void> Function() onRefresh;
  const _RequestsTab({required this.requests, required this.onRefresh});

  Future<void> _cancel(BuildContext context, WidgetRef ref, SlipRequest r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('The Registrar will no longer see it. You can request again later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(admissionSlipsRepositoryProvider).cancel(r.id);
      ref.invalidate(admissionSlipsProvider);
      ref.invalidate(portalDashboardProvider);
    } catch (e) {
      if (context.mounted) showErrorSnack(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
          children: const [
            EmptyState(
              icon: Icons.assignment_rounded,
              headline: 'No requests yet',
              subtext: 'Select an item on the Needs Slip tab to ask the Registrar for a slip.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final r = requests[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Request #${r.id}', style: AppTextStyles.cardTitle)),
                      PortalStatusChip.forStatus(r.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final it in r.items)
                    Text('${it.label} · ${_fmtDate(it.date)}', style: AppTextStyles.body),
                  const SizedBox(height: 6),
                  Text('Your reason: ${r.reason}', style: AppTextStyles.caption),
                  if (r.decisionNote != null && r.decisionNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(r.decisionNote!, style: AppTextStyles.body),
                    ),
                  ],
                  if (r.status == 'pending')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _cancel(context, ref, r),
                        child: const Text('Cancel request'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IssuedTab extends ConsumerStatefulWidget {
  final List<IssuedSlip> slips;
  final Future<void> Function() onRefresh;
  const _IssuedTab({required this.slips, required this.onRefresh});

  @override
  ConsumerState<_IssuedTab> createState() => _IssuedTabState();
}

class _IssuedTabState extends ConsumerState<_IssuedTab> {
  int? _downloadingId;

  Future<void> _download(IssuedSlip s) async {
    setState(() => _downloadingId = s.id);
    try {
      final bytes = await ref.read(admissionSlipsRepositoryProvider).downloadSlipPdf(s.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Admission_Slip_${s.id}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Class Admission Slip',
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slips.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
          children: const [
            EmptyState(
              icon: Icons.verified_rounded,
              headline: 'No slips issued yet',
              subtext: 'Slips the Registrar issues to you will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: widget.slips.length,
        itemBuilder: (_, i) {
          final s = widget.slips[i];
          final excused = s.excusedStatus == 'excused';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(_fmtDate(s.infractionDate), style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        PortalStatusChip(
                          label: excused ? 'Excused' : 'Unexcused',
                          color: excused ? AppColors.successText : AppColors.dangerText,
                          bg: excused ? AppColors.successBg : AppColors.dangerBg,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _downloadingId == null ? () => _download(s) : null,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Download PDF'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
