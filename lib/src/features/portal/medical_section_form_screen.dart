import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

const _sectionTitles = <String, String>{
  'allergies': 'Allergies',
  'immunizations': 'Immunizations',
  'medical_history': 'Medical History',
  'vitamins': 'Vitamins & Supplements',
};

const _sectionHints = <String, String>{
  'allergies': 'List any allergies and the medication or treatment used.',
  'immunizations': 'List all vaccines you have received.',
  'medical_history': 'List past illnesses, injuries, or conditions.',
  'vitamins': 'List vitamins or supplements you regularly take.',
};

/// One medical-records section form (repeating rows), pre-filled from the API.
class MedicalSectionFormScreen extends ConsumerWidget {
  final String section;
  const MedicalSectionFormScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(medicalRecordsProvider);
    final title = _sectionTitles[section] ?? 'Medical';

    return data.when(
      loading: () => PortalSubScreen(
        title: title,
        body: const ShimmerList(count: 4, itemHeight: 84),
      ),
      error: (e, _) => PortalSubScreen(
        title: title,
        body: ErrorRetryView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(medicalRecordsProvider),
        ),
      ),
      data: (d) => _MedicalForm(
        section: section,
        title: title,
        existing:
            ((d['existing'] as Map<String, dynamic>?) ?? const {})[section]
                    as List? ??
                const [],
      ),
    );
  }
}

class _MedicalRow {
  final Map<String, TextEditingController> text;
  String allergy; // allergies only: 'yes' | 'no'
  String? date; // immunizations/history/vitamins date
  bool opd;
  bool confinement;

  _MedicalRow({
    required this.text,
    this.allergy = 'no',
    this.date,
    this.opd = false,
    this.confinement = false,
  });

  void dispose() {
    for (final c in text.values) {
      c.dispose();
    }
  }
}

class _MedicalForm extends ConsumerStatefulWidget {
  final String section;
  final String title;
  final List existing;

  const _MedicalForm(
      {required this.section, required this.title, required this.existing});

  @override
  ConsumerState<_MedicalForm> createState() => _MedicalFormState();
}

class _MedicalFormState extends ConsumerState<_MedicalForm> {
  bool _saving = false;
  final List<_MedicalRow> _rows = [];

  @override
  void initState() {
    super.initState();
    for (final raw in widget.existing) {
      final row = raw as Map;
      _rows.add(_newRow(row));
    }
    if (_rows.isEmpty) _rows.add(_newRow(null));
  }

  _MedicalRow _newRow(Map? row) {
    switch (widget.section) {
      case 'allergies':
        return _MedicalRow(
          text: {
            'medication':
                TextEditingController(text: '${row?['medication'] ?? ''}')
          },
          allergy: '${row?['allergy'] ?? 'no'}',
        );
      case 'immunizations':
        return _MedicalRow(
          text: {
            'vaccine': TextEditingController(text: '${row?['vaccine'] ?? ''}')
          },
          date: _dateOnly(row?['date_administered']),
        );
      case 'medical_history':
        return _MedicalRow(
          text: {
            'disease': TextEditingController(text: '${row?['disease'] ?? ''}')
          },
          date: _dateOnly(row?['date_sustained']),
          opd: row?['opd'] == 1 || row?['opd'] == true,
          confinement: row?['hospital_confinement'] == 1 ||
              row?['hospital_confinement'] == true,
        );
      default: // vitamins
        return _MedicalRow(
          text: {
            'vitamin': TextEditingController(text: '${row?['vitamin'] ?? ''}')
          },
          date: _dateOnly(row?['date_taken']),
        );
    }
  }

  String? _dateOnly(dynamic value) {
    final s = value?.toString() ?? '';
    if (s.isEmpty) return null;
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    switch (widget.section) {
      case 'allergies':
        return {
          'allergies': [
            for (final r in _rows)
              if (r.allergy == 'yes' ||
                  r.text['medication']!.text.trim().isNotEmpty)
                {
                  'allergy': r.allergy,
                  'medication': r.text['medication']!.text.trim().isEmpty
                      ? null
                      : r.text['medication']!.text.trim(),
                },
          ],
        };
      case 'immunizations':
        return {
          'immunizations': [
            for (final r in _rows)
              if (r.text['vaccine']!.text.trim().isNotEmpty)
                {
                  'vaccine': r.text['vaccine']!.text.trim(),
                  'date_administered': r.date,
                },
          ],
        };
      case 'medical_history':
        return {
          'history': [
            for (final r in _rows)
              if (r.text['disease']!.text.trim().isNotEmpty)
                {
                  'disease': r.text['disease']!.text.trim(),
                  'date_sustained': r.date,
                  'opd': r.opd,
                  'hospital_confinement': r.confinement,
                },
          ],
        };
      default:
        return {
          'vitamins': [
            for (final r in _rows)
              if (r.text['vitamin']!.text.trim().isNotEmpty)
                {
                  'vitamin': r.text['vitamin']!.text.trim(),
                  'date_taken': r.date,
                },
          ],
        };
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/student/portal/medical/${widget.section}',
              data: _payload());
      refreshPortal(ref);
      if (mounted) {
        showSuccessSnack(context, 'Records saved successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PortalSubScreen(
        title: widget.title,
        bottomBar: SaveBar(saving: _saving, onSave: _save),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _sectionHints[widget.section] ?? '',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            WhiteCard(
              child: Column(
                children: [
                  for (var i = 0; i < _rows.length; i++)
                    RepeaterCard(
                      onRemove: () => setState(() {
                        _rows[i].dispose();
                        _rows.removeAt(i);
                      }),
                      child: _rowFields(_rows[i]),
                    ),
                  AddRowButton(
                    label: _addLabel(),
                    onTap: () => setState(() => _rows.add(_newRow(null))),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _addLabel() => switch (widget.section) {
        'allergies' => 'Add allergy',
        'immunizations' => 'Add vaccine',
        'medical_history' => 'Add record',
        _ => 'Add vitamin',
      };

  Widget _rowFields(_MedicalRow row) {
    switch (widget.section) {
      case 'allergies':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChoicePicker(
              label: 'Has allergy?',
              options: const ['no', 'yes'],
              optionLabels: const ['No', 'Yes'],
              value: row.allergy,
              onChanged: (v) => setState(() => row.allergy = v ?? 'no'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: row.text['medication'],
              enabled: row.allergy == 'yes',
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Medication / details',
                hintText: 'e.g. Amoxicillin, antihistamine',
                isDense: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        );
      case 'immunizations':
        return Column(
          children: [
            TextField(
              controller: row.text['vaccine'],
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Vaccine name',
                hintText: 'e.g. COVID-19 (Pfizer), HPV Dose 1',
                isDense: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            DateField(
              label: 'Date administered',
              value: row.date,
              onChanged: (v) => setState(() => row.date = v),
            ),
          ],
        );
      case 'medical_history':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: row.text['disease'],
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Disease / condition',
                hintText: 'e.g. Dengue, Chicken Pox',
                isDense: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            DateField(
              label: 'Date',
              value: row.date,
              onChanged: (v) => setState(() => row.date = v),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: row.opd,
                    onChanged: (v) => setState(() => row.opd = v ?? false),
                    title: Text('OPD visit',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    value: row.confinement,
                    onChanged: (v) =>
                        setState(() => row.confinement = v ?? false),
                    title: Text('Confinement',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        );
      default: // vitamins
        return Column(
          children: [
            TextField(
              controller: row.text['vitamin'],
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Vitamin / supplement',
                hintText: 'e.g. Vitamin C, Multivitamins',
                isDense: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            DateField(
              label: 'Since when (optional)',
              value: row.date,
              onChanged: (v) => setState(() => row.date = v),
            ),
          ],
        );
    }
  }
}
