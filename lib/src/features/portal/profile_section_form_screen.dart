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
  'academic': 'Academic Preferences',
  'activities': 'Activities & Awards',
  'social': 'Social & Personality',
  'career': 'Career & Vocation',
  'residence': 'Residence & Transport',
  'health': 'Physical Health',
};

/// One guidance-profile section form, pre-filled from the API.
class ProfileSectionFormScreen extends ConsumerWidget {
  final String section;
  const ProfileSectionFormScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(guidanceProfileProvider);
    final title = _sectionTitles[section] ?? 'Profile';

    return data.when(
      loading: () => PortalSubScreen(
        title: title,
        body: const ShimmerList(count: 5, itemHeight: 64),
      ),
      error: (e, _) => PortalSubScreen(
        title: title,
        body: ErrorRetryView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(guidanceProfileProvider),
        ),
      ),
      data: (d) => _ProfileForm(
        section: section,
        title: title,
        existing: (d['existing'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final String section;
  final String title;
  final Map<String, dynamic> existing;

  const _ProfileForm(
      {required this.section, required this.title, required this.existing});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  bool _saving = false;

  // Simple text fields keyed by API field name
  final Map<String, TextEditingController> _text = {};

  // Ratings / choices keyed by API field name
  final Map<String, int?> _ratings = {};
  final Map<String, String?> _choices = {};

  // Repeater rows: list of {field: controller}
  final Map<String, List<Map<String, TextEditingController>>> _rows = {};

  Map<String, dynamic>? _row(String key) =>
      widget.existing[key] as Map<String, dynamic>?;

  List _list(String key) => (widget.existing[key] as List?) ?? const [];

  TextEditingController _c(String field, String? initial) =>
      _text.putIfAbsent(field, () => TextEditingController(text: initial ?? ''));

  @override
  void initState() {
    super.initState();
    switch (widget.section) {
      case 'academic':
        final a = _row('academic');
        for (final f in _academicFields.keys) {
          _c(f, a?[f] as String?);
        }
      case 'activities':
        _initRows('clubs', ['clubname', 'position'], _list('clubs'));
        _initRows('activities', ['activityname', 'category', 'involvement'],
            _list('activities'));
        _initRows('awards', ['competition', 'award', 'category'],
            _list('awards'));
      case 'social':
        _c('traits', _row('personality')?['traits'] as String?);
        final sa = _row('selfassessment');
        for (final f in _ratingFields.keys) {
          _ratings[f] = int.tryParse('${sa?[f] ?? ''}');
        }
        final st = _row('statements');
        for (var i = 1; i <= 10; i++) {
          _c('state$i', st?['state$i'] as String?);
        }
        final fa = _row('friend_age');
        final fg = _row('friend_group');
        for (final f in _friendFields.keys) {
          final src = ['fr_age', 'fr_older', 'fr_younger'].contains(f) ? fa : fg;
          _choices[f] = (src?[f] as String?)?.isEmpty ?? true
              ? null
              : src![f] as String?;
        }
        _initRows('friends', ['fr_name'],
            _list('friends').map((e) => {'fr_name': e['fr_name']}).toList());
        _initRows('talents', ['talent'],
            _list('talents').map((e) => {'talent': e['talent']}).toList());
      case 'career':
        final v = _row('vocational');
        _c('1stchoice', v?['1stchoice'] as String?);
        _c('2ndchoice', v?['2ndchoice'] as String?);
      case 'residence':
        final r = _row('residence');
        _choices['residencetype'] = r?['residencetype'] as String?;
        _choices['transportation'] = r?['transportation'] as String?;
      case 'health':
        final h = _row('health');
        _c('weight', h?['weight'] as String?);
        _c('height', h?['height'] as String?);
        _c('general_health', h?['general_health'] as String?);
        _c('ailment_remarks', h?['ailment_remarks'] as String?);
        for (final f in ['sight', 'hearing', 'speech', 'ailment']) {
          _choices[f] = (h?[f] as String?) ?? 'No';
        }
    }
  }

  void _initRows(String key, List<String> fields, List existing) {
    _rows[key] = [
      for (final row in existing)
        {
          for (final f in fields)
            f: TextEditingController(text: '${(row as Map)[f] ?? ''}')
        },
    ];
    if (_rows[key]!.isEmpty) _addRow(key, fields);
  }

  void _addRow(String key, List<String> fields) {
    _rows[key]!.add({for (final f in fields) f: TextEditingController()});
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final rows in _rows.values) {
      for (final row in rows) {
        for (final c in row.values) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  // ── Payload ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _payload() {
    String? t(String f) {
      final v = _text[f]?.text.trim() ?? '';
      return v.isEmpty ? null : v;
    }

    List<Map<String, String>> rows(String key, String requiredField) => [
          for (final row in _rows[key] ?? const [])
            if ((row[requiredField]!.text.trim()).isNotEmpty)
              {
                for (final e in row.entries)
                  if (e.value.text.trim().isNotEmpty)
                    e.key: e.value.text.trim()
              },
        ];

    switch (widget.section) {
      case 'academic':
        return {for (final f in _academicFields.keys) f: t(f)};
      case 'activities':
        return {
          'clubs': rows('clubs', 'clubname'),
          'activities': rows('activities', 'activityname'),
          'awards': rows('awards', 'competition'),
        };
      case 'social':
        return {
          'traits': t('traits'),
          for (final f in _ratingFields.keys) f: _ratings[f],
          for (var i = 1; i <= 10; i++) 'state$i': t('state$i'),
          for (final f in _friendFields.keys) f: _choices[f],
          'friends': [
            for (final row in _rows['friends'] ?? const [])
              if (row['fr_name']!.text.trim().isNotEmpty)
                row['fr_name']!.text.trim()
          ],
          'talents': [
            for (final row in _rows['talents'] ?? const [])
              if (row['talent']!.text.trim().isNotEmpty)
                row['talent']!.text.trim()
          ],
        };
      case 'career':
        return {'1stchoice': t('1stchoice'), '2ndchoice': t('2ndchoice')};
      case 'residence':
        return {
          'residencetype': _choices['residencetype'],
          'transportation': _choices['transportation'],
        };
      case 'health':
        return {
          'weight': t('weight'),
          'height': t('height'),
          'sight': _choices['sight'],
          'hearing': _choices['hearing'],
          'speech': _choices['speech'],
          'general_health': t('general_health'),
          'ailment': _choices['ailment'],
          'ailment_remarks': t('ailment_remarks'),
        };
    }
    return {};
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/student/portal/profile/${widget.section}', data: _payload());
      refreshPortal(ref);
      if (mounted) {
        showSuccessSnack(context, 'Section saved successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => PortalSubScreen(
        title: widget.title,
        bottomBar: SaveBar(saving: _saving, onSave: _save),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: _fields(),
        ),
      );

  List<Widget> _fields() {
    switch (widget.section) {
      case 'academic':
        return [
          _card([
            for (final e in _academicFields.entries) ...[
              _textField(e.key, e.value),
              const SizedBox(height: 14),
            ],
          ]),
        ];
      case 'activities':
        return [
          const SectionLabel('CLUB MEMBERSHIPS'),
          _repeater('clubs', ['clubname', 'position'],
              ['Club name', 'Position (optional)'], 'Add club'),
          const SizedBox(height: 20),
          const SectionLabel('ACTIVITY PARTICIPATION'),
          _repeater(
              'activities',
              ['activityname', 'category', 'involvement'],
              ['Activity name', 'Category (optional)', 'Involvement (optional)'],
              'Add activity'),
          const SizedBox(height: 20),
          const SectionLabel('AWARDS & COMPETITIONS'),
          _repeater('awards', ['competition', 'award', 'category'],
              ['Competition', 'Award / place (optional)', 'Level (optional)'],
              'Add award'),
        ];
      case 'social':
        return [
          const SectionLabel('PERSONALITY'),
          _card([
            _textField('traits', 'Describe your personality traits',
                maxLines: 3),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('SELF-ASSESSMENT  ·  1 = EXCELLENT, 5 = POOR'),
          _card([
            for (final e in _ratingFields.entries)
              RatingPicker(
                label: e.value,
                value: _ratings[e.key],
                onChanged: (v) => setState(() => _ratings[e.key] = v),
              ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('COMPLETE THESE STATEMENTS'),
          _card([
            for (var i = 1; i <= 10; i++) ...[
              _textField('state$i', _selfLabels[i - 1]),
              const SizedBox(height: 14),
            ],
          ]),
          const SizedBox(height: 20),
          const SectionLabel('FRIENDS'),
          _repeater('friends', ['fr_name'], ["Friend's name"], 'Add friend'),
          const SizedBox(height: 16),
          _card([
            for (final e in _friendFields.entries) ...[
              ChoicePicker(
                label: e.value,
                options: const ['Yes', 'No'],
                value: _choices[e.key],
                onChanged: (v) => setState(() => _choices[e.key] = v),
              ),
              const SizedBox(height: 14),
            ],
          ]),
          const SizedBox(height: 20),
          const SectionLabel('TALENTS'),
          _repeater('talents', ['talent'], ['e.g. Playing guitar'],
              'Add talent'),
        ];
      case 'career':
        return [
          _card([
            _textField('1stchoice', '1st choice career (e.g. Medical Doctor)'),
            const SizedBox(height: 14),
            _textField('2ndchoice', '2nd choice career (e.g. Engineer)'),
          ]),
        ];
      case 'residence':
        return [
          _card([
            ChoicePicker(
              label: 'Residence type while studying',
              options: const [
                'Family Home',
                'School Dormitory',
                'Boarding House',
                'Relatives'
              ],
              value: _choices['residencetype'],
              onChanged: (v) => setState(() => _choices['residencetype'] = v),
            ),
            const SizedBox(height: 18),
            ChoicePicker(
              label: 'Mode of transportation',
              options: const [
                'Family-owned vehicle',
                'Car-pool',
                'Public transportation',
                'Service',
                'Walking',
                'N/A'
              ],
              value: _choices['transportation'],
              onChanged: (v) => setState(() => _choices['transportation'] = v),
            ),
          ]),
        ];
      case 'health':
        return [
          _card([
            Row(children: [
              Expanded(child: _textField('weight', 'Weight (kg)')),
              const SizedBox(width: 12),
              Expanded(child: _textField('height', 'Height (cm)')),
            ]),
            const SizedBox(height: 18),
            for (final e in {
              'sight': 'Sight issue?',
              'hearing': 'Hearing issue?',
              'speech': 'Speech issue?',
            }.entries) ...[
              ChoicePicker(
                label: e.value,
                options: const ['No', 'Yes'],
                value: _choices[e.key],
                onChanged: (v) =>
                    setState(() => _choices[e.key] = v ?? 'No'),
              ),
              const SizedBox(height: 14),
            ],
            _textField('general_health', 'General health condition'),
            const SizedBox(height: 18),
            ChoicePicker(
              label: 'Any ailment?',
              options: const ['No', 'Yes'],
              value: _choices['ailment'],
              onChanged: (v) => setState(() => _choices['ailment'] = v ?? 'No'),
            ),
            if (_choices['ailment'] == 'Yes') ...[
              const SizedBox(height: 14),
              _textField('ailment_remarks', 'Ailment details'),
            ],
          ]),
        ];
    }
    return const [];
  }

  Widget _card(List<Widget> children) => WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _textField(String field, String label, {int maxLines = 1}) =>
      TextField(
        controller: _text[field],
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(fontSize: 14),
        decoration: InputDecoration(labelText: label),
      );

  Widget _repeater(String key, List<String> fields, List<String> hints,
          String addLabel) =>
      WhiteCard(
        child: Column(
          children: [
            for (var i = 0; i < (_rows[key]?.length ?? 0); i++)
              RepeaterCard(
                onRemove: () => setState(() {
                  for (final c in _rows[key]![i].values) {
                    c.dispose();
                  }
                  _rows[key]!.removeAt(i);
                }),
                child: Column(
                  children: [
                    for (var f = 0; f < fields.length; f++) ...[
                      if (f > 0) const SizedBox(height: 10),
                      TextField(
                        controller: _rows[key]![i][fields[f]],
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: hints[f],
                          isDense: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            AddRowButton(
              label: addLabel,
              onTap: () => setState(() => _addRow(key, fields)),
            ),
          ],
        ),
      );
}

// ── Field definitions (mirror the web portal) ─────────────────────────────────

const _academicFields = <String, String>{
  'subject_like': 'Subject you like most',
  'subject_least': 'Subject you like least',
  'subject_difficult': 'Most difficult subject',
  'subjectlearnedmost': 'Subject you learned from most',
  'subjectlearnedleast': 'Subject you learned from least',
  'subjecttaugtbest': 'Best-taught subject',
  'subjecttaugtworst': 'Least-taught subject',
};

const _ratingFields = <String, String>{
  'physical': 'Physical',
  'mental': 'Mental / Academic',
  'speech_en': 'English Communication',
  'speech_fil': 'Filipino Communication',
  'writing': 'Writing',
  'personality': 'Personality',
  'character1': 'Character',
};

const _friendFields = <String, String>{
  'fr_age': 'Friends same age?',
  'fr_older': 'Friends older than you?',
  'fr_younger': 'Friends younger than you?',
  'fr_boys': 'Friends who are boys?',
  'fr_girls': 'Friends who are girls?',
  'fr_otherschool': 'Friends from other schools?',
  'fr_fromthischool': 'Friends from PSHS-CRC?',
};

const _selfLabels = [
  'My parents…',
  'My greatest mistake was…',
  'I wish…',
  'My teachers…',
  'I like my friends because…',
  'My family…',
  'I always wanted to…',
  'My mother/father…',
  'At school, I get along with…',
  'My role model…',
];
