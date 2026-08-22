import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';

void main() {
  test('hero gradient goes from pastel blue to pastel green', () {
    expect(AppGradients.hero.colors.first, const Color(0xFF4F86E8));
    expect(AppGradients.hero.colors.last, const Color(0xFF8FE3A9));
  });

  test('hero and button gradients keep blue dominant over green', () {
    // Blue must stay solid for at least half the gradient before any
    // blend toward green begins — green is a corner accent, not an
    // equal partner.
    final heroBlendStart = AppGradients.hero.stops![1];
    final buttonBlendStart = AppGradients.button.stops![1];
    expect(heroBlendStart, greaterThanOrEqualTo(0.5));
    expect(buttonBlendStart, greaterThanOrEqualTo(0.5));
    expect(AppGradients.button.colors.first, const Color(0xFF4F86E8));
    expect(AppGradients.button.colors.last, const Color(0xFF8FE3A9));
  });

  test('soft-danger status tokens exist and are distinct from warning', () {
    expect(AppColors.dangerBg, isNot(equals(AppColors.warningBg)));
    expect(AppColors.dangerText, isNot(equals(AppColors.warningText)));
  });
}
