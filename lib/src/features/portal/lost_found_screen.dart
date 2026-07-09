import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

/// Lost & Found — browse found items in GSU custody, track own reports,
/// and file lost/found reports. Turning over a found item to the GSU
/// office earns honesty points once GSU confirms receipt.
class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen> {
  int _tab = 0; // 0 = found items board, 1 = my reports

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(lostFoundProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Report Item',
            style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () => _openReportSheet(context),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(lostFoundProvider),
        child: data.when(
          loading: () => const ShimmerList(count: 4, itemHeight: 92),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(lostFoundProvider),
              ),
            ],
          ),
          data: (d) {
            final board = (d['board'] as List?) ?? const [];
            final myReports = (d['my_reports'] as List?) ?? const [];
            final points = (d['my_points'] as int?) ?? 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              children: [
                _PointsBanner(points: points),
                const SizedBox(height: 14),
                _TabBar(
                  tab: _tab,
                  boardCount: board.length,
                  mineCount: myReports.length,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: 14),
                if (_tab == 0) ...[
                  if (board.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.inventory_2_rounded,
                        headline: 'No items in GSU custody',
                        subtext:
                            'Found items turned over to the GSU office will appear here so owners can claim them.',
                      ),
                    )
                  else
                    ...board.map((item) => _BoardCard(
                        item: item as Map<String, dynamic>)),
                ] else ...[
                  if (myReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.assignment_rounded,
                        headline: 'No reports yet',
                        subtext:
                            'Lost something? Found something? File a report with the button below.',
                      ),
                    )
                  else
                    ...myReports.map((item) => _ReportCard(
                        item: item as Map<String, dynamic>)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    final categories =
        (ref.read(lostFoundProvider).value?['categories'] as Map?) ?? const {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ReportItemSheet(
          categories: categories.map((k, v) => MapEntry('$k', '$v'))),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PointsBanner extends StatelessWidget {
  final int points;
  const _PointsBanner({required this.points});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$points Honesty Points',
                      style: AppTextStyles.custom(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
                  Text(
                      'Earn 10 points per found item turned over to the GSU office.',
                      style: AppTextStyles.custom(fontSize: 11.5, color: const Color(0xFFB45309))),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TabBar extends StatelessWidget {
  final int tab;
  final int boardCount;
  final int mineCount;
  final ValueChanged<int> onChanged;

  const _TabBar({
    required this.tab,
    required this.boardCount,
    required this.mineCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            _tabButton('Found Items ($boardCount)', 0),
            _tabButton('My Reports ($mineCount)', 1),
          ],
        ),
      );

  Widget _tabButton(String label, int index) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: tab == index ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: 12.5, fontWeight: FontWeight.w700, color: tab == index
                        ? Colors.white
                        : AppColors.textSecondary)),
          ),
        ),
      );
}

class _ItemPhoto extends ConsumerWidget {
  final int itemId;
  static const double size = 64;
  const _ItemPhoto({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(lostFoundPhotoProvider(itemId));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: photo.when(
          loading: () => Container(color: AppColors.borderLight),
          error: (_, stack) => _placeholder(),
          data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.borderLight,
        child: const Icon(Icons.inventory_2_rounded,
            color: AppColors.textDisabled, size: 26),
      );
}

String _fmtDate(dynamic raw) {
  if (raw == null) return '—';
  try {
    return DateFormat('MMM d, y').format(DateTime.parse(raw.toString()));
  } catch (_) {
    return raw.toString();
  }
}

class _BoardCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _BoardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item['has_photo'] == true;
    final location = item['location']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPhoto)
              _ItemPhoto(itemId: (item['id'] as num).toInt())
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2_rounded,
                    color: AppColors.textDisabled, size: 26),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['item_name']?.toString() ?? '—',
                      style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w700)),
                  if ((item['category_label']?.toString() ?? '').isNotEmpty)
                    Text(item['category_label'].toString(),
                        style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    'Found ${_fmtDate(item['date_lost_found'])}'
                    '${location.isNotEmpty ? ' · $location' : ''}',
                    style: AppTextStyles.custom(fontSize: 11.5, color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 4),
                  Text('Yours? Claim it at the GSU office.',
                      style: AppTextStyles.custom(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isFound = item['type'] == 'found';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFound
                        ? AppColors.successBg
                        : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(isFound ? 'Found' : 'Lost',
                      style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w700, color: isFound
                              ? AppColors.successText
                              : AppColors.warningText)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['item_name']?.toString() ?? '—',
                      style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_fmtDate(item['date_lost_found']),
                style: AppTextStyles.custom(fontSize: 11.5, color: AppColors.textDisabled)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item['custody_label']?.toString() ?? '—',
                        style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Report sheet ─────────────────────────────────────────────────────────────

class _ReportItemSheet extends ConsumerStatefulWidget {
  final Map<String, String> categories;
  const _ReportItemSheet({required this.categories});

  @override
  ConsumerState<_ReportItemSheet> createState() => _ReportItemSheetState();
}

class _ReportItemSheetState extends ConsumerState<_ReportItemSheet> {
  bool _saving = false;
  String _type = 'lost';
  String? _category;
  DateTime _date = DateTime.now();
  String? _photoBase64;
  final _itemName = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _itemName.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(
        () => _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _submit() async {
    if (_itemName.text.trim().isEmpty) {
      showErrorSnack(context, 'Item name is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ref.read(apiClientProvider).post(
        '/student/portal/lost-found',
        data: {
          'type': _type,
          'item_name': _itemName.text.trim(),
          'description': _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          'category': _category,
          'location':
              _location.text.trim().isEmpty ? null : _location.text.trim(),
          'date_lost_found': DateFormat('yyyy-MM-dd').format(_date),
          'photo_base64': _photoBase64,
        },
      );
      ref.invalidate(lostFoundProvider);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnack(
            context,
            (response.data as Map?)?['message']?.toString() ??
                'Report submitted.');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFound = _type == 'found';

    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report an Item',
                style: AppTextStyles.custom(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ChoicePicker(
              label: 'What happened?',
              options: const ['lost', 'found'],
              optionLabels: const ['I lost an item', 'I found an item'],
              value: _type,
              onChanged: (v) => setState(() => _type = v ?? 'lost'),
            ),
            if (isFound) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Bring the item to the GSU office — you\'ll earn 10 honesty points once GSU confirms the turnover.',
                  style: AppTextStyles.custom(fontSize: 12, color: AppColors.successText),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _itemName,
              style: AppTextStyles.custom(fontSize: 14),
              decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Blue water bottle, calculator'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              style: AppTextStyles.custom(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isFound ? 'Date found' : 'Date lost',
                  suffixIcon:
                      const Icon(Icons.calendar_today_rounded, size: 16),
                ),
                child: Text(DateFormat('MMM d, y').format(_date),
                    style: AppTextStyles.custom(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _location,
              style: AppTextStyles.custom(fontSize: 14),
              decoration: InputDecoration(
                  labelText: isFound
                      ? 'Where did you find it?'
                      : 'Where did you last see it?',
                  hintText: 'e.g. Canteen, Room 204, Gym'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              maxLines: 2,
              style: AppTextStyles.custom(fontSize: 14),
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Color, brand, distinguishing marks…'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text('Camera',
                        style: AppTextStyles.custom(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text('Gallery',
                        style: AppTextStyles.custom(fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (_photoBase64 != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(_photoBase64!.split(',').last),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () => setState(() => _photoBase64 = null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Remove photo',
                        style: AppTextStyles.custom(fontSize: 12.5)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Submit Report',
                        style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
