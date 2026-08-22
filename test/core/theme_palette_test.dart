import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';

void main() {
  test('hero gradient goes from brand navy to emerald', () {
    expect(AppGradients.hero.colors.first, const Color(0xFF1A3557));
    expect(AppGradients.hero.colors.last, const Color(0xFF34D399));
  });

  test('soft-danger status tokens exist and are distinct from warning', () {
    expect(AppColors.dangerBg, isNot(equals(AppColors.warningBg)));
    expect(AppColors.dangerText, isNot(equals(AppColors.warningText)));
  });
}
