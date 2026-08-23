import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'student_id_card_scale.dart';
import 'student_provider.dart';

const _kBlue = Color(0xFF1447C0);
const _kSlate = Color(0xFF475569);
const _kSlateLight = Color(0xFF94A3B8);
const _kSlateDark = Color(0xFF1E293B);
const _kDivider = Color(0xFFF1F5F9);

/// Back face of the digital student ID — mirrors
/// resources/js/Pages/Students/IdCard.vue's back side field-for-field:
/// emergency contact block, notice paragraphs, "Valid for School Year"
/// label (no value, matching the physical card's printed template — the
/// year is meant for a validation sticker), and a repeated barcode footer.
class StudentIdCardBack extends StatelessWidget {
  final StudentIdCard card;
  final double cardWidth;

  const StudentIdCardBack({super.key, required this.card, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final s = CardScale(cardWidth);
    final cardHeight = cardWidth * 86 / 54;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s.mm(2.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: s.mm(2), vertical: s.mm(1.5)),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBlue, width: 1.5))),
            child: Text('IN CASE OF EMERGENCY, NOTIFY',
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: s.px(9), fontWeight: FontWeight.w700, color: _kBlue, letterSpacing: 0.5)),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: s.mm(3), vertical: s.mm(2.5)),
              // Same scroll-safety net as StudentIdCardFront — the back
              // face packs four notice paragraphs into a similarly tight
              // mm budget as the print CSS.
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(s, 'NAME OF PARENT / GUARDIAN', card.guardianName, first: true),
                    _field(s, 'CONTACT NUMBER', card.contactNo),
                    _field(s, 'ADDRESS', card.address),
                    Container(width: double.infinity, height: 1, color: _kDivider, margin: EdgeInsets.symmetric(vertical: s.mm(1))),
                    Text('IMPORTANT',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.custom(fontSize: s.px(6.5), fontWeight: FontWeight.w700, color: _kBlue, letterSpacing: 0.5)),
                    SizedBox(height: s.mm(1)),
                    _notice(s, 'This ID is valid for the period indicated on the validation sticker.'),
                    _notice(s, 'This ID is non-transferable and should be worn visibly at all times while inside the campus.'),
                    _notice(s, 'This ID must be surrendered upon graduation.'),
                    _notice(s,
                        'Lost ID cards will be replaced only upon presentation of an affidavit of loss to the Office of the Registrar.',
                        last: true),
                    SizedBox(height: s.mm(3)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: s.mm(1.5)),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kDivider))),
                      child: Text('VALID FOR SCHOOL YEAR',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.custom(fontSize: s.px(7), fontWeight: FontWeight.w700, color: _kBlue, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: s.mm(11),
            padding: EdgeInsets.symmetric(horizontal: s.mm(3), vertical: s.mm(1.5)),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBlue, width: 1.5))),
            alignment: Alignment.center,
            child: (card.barcode == null || card.barcode!.isEmpty)
                ? const SizedBox.shrink()
                : BarcodeWidget(barcode: idSymbology, data: card.barcode!, drawText: false, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _field(CardScale s, String label, String? value, {bool first = false}) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: first ? s.mm(0.5) : s.mm(1.5)),
        child: Column(
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: s.px(6), fontWeight: FontWeight.w700, color: _kSlateLight, letterSpacing: 0.5)),
            SizedBox(height: s.mm(0.5)),
            Text(value ?? '—',
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: s.px(8), fontWeight: FontWeight.w600, color: _kSlateDark)),
          ],
        ),
      );

  Widget _notice(CardScale s, String text, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : s.mm(1)),
        child: Text(text,
            textAlign: TextAlign.justify,
            style: AppTextStyles.custom(fontSize: s.px(6), color: _kSlate, height: 1.4)),
      );
}
