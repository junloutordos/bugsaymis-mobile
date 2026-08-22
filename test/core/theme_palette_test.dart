import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/core/theme.dart';

void main() {
  test('hero gradient goes from pastel blue to pastel green', () {
    expect(AppGradients.hero.colors.first, const Color(0xFF4F86E8));
    expect(AppGradients.hero.colors.last, const Color(0xFF8FE3A9));
  });

  test('soft-danger status tokens exist and are distinct from warning', () {
    expect(AppColors.dangerBg, isNot(equals(AppColors.warningBg)));
    expect(AppColors.dangerText, isNot(equals(AppColors.warningText)));
  });
}
