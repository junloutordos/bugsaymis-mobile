import 'dart:convert';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'student_id_card_scale.dart';
import 'student_photo_image.dart';
import 'student_provider.dart';

const _kBandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF060E50), Color(0xFF1447C0), Color(0xFF0093B8)],
  stops: [0.0, 0.65, 1.0],
);
const _kSlateDark = Color(0xFF1E293B);
const _kSlate = Color(0xFF475569);
const _kSlateLight = Color(0xFF94A3B8);
const _kBorderLight = Color(0xFFE2E8F0);
const _kDivider = Color(0xFFF1F5F9);

/// Front face of the digital student ID — mirrors
/// resources/js/Pages/Students/IdCard.vue (the backend's printable CR-80
/// template) field-for-field: header band, photo, name, barcode, LRN,
/// OCD signature block, "SCHOLAR" footer band.
class StudentIdCardFront extends StatelessWidget {
  final StudentIdCard card;
  final double cardWidth;

  const StudentIdCardFront({super.key, required this.card, required this.cardWidth});

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
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset('assets/images/id_card_bg.jpg', fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          ),
          Column(
            children: [
              _band(s),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: s.mm(3), vertical: s.mm(2.5)),
                  // Wraps in a scroll view as a safety net: the print CSS's
                  // "margin-top: auto" only has a few mm of slack between the
                  // LRN block and the signature, and platform font-metric
                  // variance can eat that — a graceful scroll beats a red
                  // overflow banner clipping the signature block.
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _photo(s),
                        SizedBox(height: s.mm(1.5)),
                        Text(
                          card.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.custom(
                            fontSize: s.px(9), fontWeight: FontWeight.w700, color: _kSlateDark, height: 1.3,
                          ),
                        ),
                        SizedBox(height: s.mm(1)),
                        _barcode(s),
                        SizedBox(height: s.mm(1)),
                        _lrn(s),
                        SizedBox(height: s.mm(1.5)),
                        _signature(s),
                      ],
                    ),
                  ),
                ),
              ),
              _footerBand(s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _band(CardScale s) => Container(
        decoration: const BoxDecoration(gradient: _kBandGradient),
        padding: EdgeInsets.symmetric(horizontal: s.mm(2), vertical: s.mm(1.5)),
        child: Row(
          children: [
            Image.asset('assets/images/pshs_logo.png', width: s.mm(9), height: s.mm(9), fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.school_rounded, color: Colors.white, size: s.mm(9))),
            SizedBox(width: s.mm(1.5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Republic of the Philippines',
                      style: AppTextStyles.custom(fontSize: s.px(5.5), color: Colors.white)),
                  Text('Department of Science and Technology',
                      style: AppTextStyles.custom(fontSize: s.px(5.5), color: Colors.white)),
                  Text('PHILIPPINE SCIENCE HIGH SCHOOL',
                      style: AppTextStyles.custom(fontSize: s.px(6.5), fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('CARAGA REGION CAMPUS IN BUTUAN CITY',
                      style: AppTextStyles.custom(fontSize: s.px(5.5), fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _photo(CardScale s) {
    final empty = Center(
      child: Text('No Photo', style: AppTextStyles.custom(fontSize: s.px(6), color: _kSlateLight)),
    );
    return Container(
      width: s.mm(30),
      height: s.mm(30),
      margin: EdgeInsets.only(top: s.mm(1)),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorderLight),
        borderRadius: BorderRadius.circular(s.mm(1.5)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: card.hasPhoto
          ? StudentPhotoImage(alignment: const Alignment(0, -0.6), child: empty)
          : empty,
    );
  }

  Widget _barcode(CardScale s) {
    final barcode = card.barcode;
    if (barcode == null || barcode.isEmpty) {
      return SizedBox(
        height: s.mm(7),
        child: Center(
          child: Text('No barcode on file', style: AppTextStyles.custom(fontSize: s.px(6.5), color: _kSlate)),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: s.mm(7),
          child: BarcodeWidget(
            barcode: idSymbology,
            data: barcode,
            drawText: false,
            color: Colors.black,
            errorBuilder: (_, _) => Text(barcode, textAlign: TextAlign.center),
          ),
        ),
        SizedBox(height: s.mm(0.5)),
        Text(barcode,
            style: AppTextStyles.custom(fontSize: s.px(6.5), fontWeight: FontWeight.w600, color: _kSlate, letterSpacing: 1)),
      ],
    );
  }

  Widget _lrn(CardScale s) => Container(
        width: double.infinity,
        padding: EdgeInsets.only(top: s.mm(1)),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kDivider))),
        child: Column(
          children: [
            Text('LEARNER REFERENCE NUMBER',
                style: AppTextStyles.custom(fontSize: s.px(6), fontWeight: FontWeight.w700, color: _kSlateLight, letterSpacing: 0.5)),
            SizedBox(height: s.mm(0.5)),
            Text(card.lrn ?? '—',
                style: AppTextStyles.custom(fontSize: s.px(9), fontWeight: FontWeight.w700, color: _kSlateDark, letterSpacing: 1)),
          ],
        ),
      );

  Widget _signature(CardScale s) => Column(
        children: [
          if (card.ocdSignatureUri != null)
            Image.memory(
              base64Decode(card.ocdSignatureUri!.split(',').last),
              height: s.mm(5),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Text(card.ocdName,
              style: AppTextStyles.custom(fontSize: s.px(7), fontWeight: FontWeight.w700, color: _kSlateDark)),
          Text(card.ocdPosition,
              style: AppTextStyles.custom(fontSize: s.px(6), color: _kSlateDark, letterSpacing: 0.5)),
        ],
      );

  Widget _footerBand(CardScale s) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: s.mm(1.5)),
        decoration: const BoxDecoration(gradient: _kBandGradient),
        child: Text('SCHOLAR',
            textAlign: TextAlign.center,
            style: AppTextStyles.custom(fontSize: s.px(8), fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
      );
}
