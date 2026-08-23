import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/student/student_id_card_scale.dart';

void main() {
  test('mm(54) equals the full card width, at any card width', () {
    expect(const CardScale(216).mm(54), closeTo(216, 0.001));
    expect(const CardScale(108).mm(54), closeTo(108, 0.001));
  });

  test('px scales proportionally with mm at the same card width', () {
    // At the print template's reference size (54mm rendered at 96dpi),
    // 1mm and (96/25.4)px are the same physical length.
    const s = CardScale(54 * 3.7795275591);
    expect(s.mm(1), closeTo(s.px(3.7795275591), 0.001));
  });
}
