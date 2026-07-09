import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
export '../../shared/widgets/app_card.dart';

/// Standard sub-screen scaffold for portal pages: white app bar with back
/// button + title, slate background body.
class PortalSubScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomBar;

  const PortalSubScreen({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(title)),
        body: body,
        bottomNavigationBar: bottomBar,
      );
}

/// Sticky bottom save bar used by all portal forms.
class SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final String label;

  const SaveBar({
    super.key,
    required this.saving,
    required this.onSave,
    this.label = 'Save Section',
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: kNavShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: GradientButton(
              text: label,
              isLoading: saving,
              onPressed: saving ? null : onSave,
            ),
          ),
        ),
      );
}

/// 1–5 rating selector as a row of tappable circles.
class RatingPicker extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  const RatingPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.custom(fontSize: 13, color: AppColors.textPrimary)),
            ),
            ...List.generate(5, (i) {
              final n = i + 1;
              final selected = value == n;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => onChanged(selected ? null : n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color:
                              selected ? AppColors.accent : AppColors.border),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: AppTextStyles.fieldLabel.copyWith(color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
}

/// Horizontal single-choice chips.
class ChoicePicker extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String>? optionLabels;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ChoicePicker({
    super.key,
    required this.label,
    required this.options,
    this.optionLabels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(options.length, (i) {
              final opt = options[i];
              final selected = value == opt;
              return ChoiceChip(
                label: Text(optionLabels != null ? optionLabels![i] : opt),
                selected: selected,
                showCheckmark: false,
                labelStyle: AppTextStyles.fieldLabel.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.background,
                side: BorderSide(
                    color: selected ? AppColors.accent : AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onSelected: (_) => onChanged(selected ? null : opt),
              );
            }),
          ),
        ],
      );
}

/// Removable entry card used by repeating lists (clubs, vaccines, …).
class RepeaterCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const RepeaterCard({super.key, required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ],
        ),
      );
}

/// "+ Add …" outlined button below a repeater list.
class AddRowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AddRowButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
        ),
      );
}

/// Tappable read-only field that opens a date picker; keeps yyyy-MM-dd.
class DateField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(value ?? '') ?? now,
            firstDate: DateTime(now.year - 25),
            lastDate: DateTime(now.year + 2),
          );
          if (picked != null) {
            onChanged(
                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
          ),
          child: Text(
            value ?? '—',
            style: AppTextStyles.custom(fontSize: 14, color: value == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary),
          ),
        ),
      );
}

/// Small colored status chip (pending / approved / cleared / …).
class PortalStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const PortalStatusChip(
      {super.key, required this.label, required this.color, required this.bg});

  factory PortalStatusChip.forStatus(String status) {
    final s = status.toLowerCase();
    if (['approved', 'cleared', 'finalized', 'confirmed', 'active', 'waived']
        .contains(s)) {
      return PortalStatusChip(
          label: status,
          color: AppColors.successText,
          bg: AppColors.successBg);
    }
    if (['rejected', 'denied', 'hold', 'returned', 'cancelled'].contains(s)) {
      return PortalStatusChip(
          label: status,
          color: const Color(0xFF7F1D1D),
          bg: const Color(0xFFFEE2E2));
    }
    if (['pending', 'waitlisted', 'open', 'in_progress'].contains(s)) {
      return PortalStatusChip(
          label: status,
          color: AppColors.warningText,
          bg: AppColors.warningBg);
    }
    return PortalStatusChip(
        label: status,
        color: AppColors.textSecondary,
        bg: AppColors.neutralBg);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _pretty(label),
          style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );

  static String _pretty(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ── Feedback helpers ──────────────────────────────────────────────────────────

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: AppColors.success,
  ));
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: Colors.red.shade600,
  ));
}

/// Human-readable message from a request failure (422 validation, offline, …).
String friendlyError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
        final first = (data['errors'] as Map).values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Check your network and try again.';
      default:
        break;
    }
    final code = error.response?.statusCode;
    if (code != null && code >= 500) {
      return 'Something went wrong on the server. Please try again later.';
    }
  }
  return 'Something went wrong. Please try again.';
}
