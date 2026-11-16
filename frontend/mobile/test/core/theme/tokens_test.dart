import 'dart:io';

import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/tokens_generator.dart';

void main() {
  test('tokens.g.dart est à jour avec frontend/design/tokens.json', () {
    final expected = generateTokens(File('../design/tokens.json').readAsStringSync());
    final actual = File('lib/core/theme/tokens.g.dart').readAsStringSync();
    expect(
      actual,
      expected,
      reason: 'La charte a changé : lancer « dart run tool/generate_tokens.dart »',
    );
  });

  test('couleurs lues dans la charte, y compris les transparences', () {
    expect(ElecPayColors.dark.bg, const Color(0xFF050D1A));
    expect(ElecPayColors.light.bg, const Color(0xFFF3F6FA));
    expect(ElecPayColors.dark.volt, const Color(0xFFF5A623));
    expect(ElecPayColors.light.voltText, const Color(0xFF9A5B00)); // jaune lisible sur fond clair
    expect(ElecPayColors.dark.glass, const Color(0x0FFFFFFF)); // rgba(255,255,255,0.06)
    expect(ElecPayColors.dark.glassStrong, const Color(0xC7102038)); // rgba(16,32,56,0.78)
  });

  test('échelle de texte, espacements, rayons et flou de la charte', () {
    expect(AppText.amountHero.fontSize, 36);
    expect(AppText.amountHero.height, closeTo(40 / 36, 0.0001));
    expect(AppText.amountHero.fontWeight, FontWeight.w700);
    expect(AppText.amountHero.letterSpacing, closeTo(-0.72, 0.0001)); // -0.02em × 36
    expect(AppText.amountHero.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(AppText.body.fontFamily, 'Poppins');
    expect(AppText.reference.fontFamily, 'JetBrainsMono');
    expect(Space.s4, 16);
    expect(Space.s12, 48); // zone tactile minimale
    expect(Radii.lg, 20);
    expect(Radii.full, 999);
    expect(Blur.glassSigma, 12);
    expect(ElecPayShadows.dark.volt.single.blurRadius, 24);
  });
}
