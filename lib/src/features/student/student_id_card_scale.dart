import 'package:barcode_widget/barcode_widget.dart';

/// The physical school IDs' symbology is not verifiable from this repo —
/// flip to Barcode.code39() if the gate scanners reject Code 128. Shared
/// by the front and back card faces (both print a copy of the barcode).
final idSymbology = Barcode.code128();

/// Converts the physical CR-80 print template's mm/px units (from
/// resources/js/Pages/Students/IdCard.vue in the backend repo, calibrated
/// at the browser's 96dpi print reference: the card is 54mm wide) into
/// logical pixels for a card rendered at [cardWidth] — so every
/// proportion (photo size, band padding, font sizes) stays faithful to
/// the physical card at any on-screen size.
class CardScale {
  static const double _mmToPx96 = 3.7795275591;
  static const double _cardWidthMm = 54;

  final double cardWidth;
  const CardScale(this.cardWidth);

  double get _factor => cardWidth / (_cardWidthMm * _mmToPx96);

  /// Converts a physical mm measurement from the print CSS.
  double mm(double v) => v * _mmToPx96 * _factor;

  /// Converts a browser px measurement from the print CSS (already
  /// expressed at the same 96dpi reference as the mm values).
  double px(double v) => v * _factor;
}
