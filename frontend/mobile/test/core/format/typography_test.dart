import 'package:elecpay/core/format/typography.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/font_cmap.dart';

/// Polices où s'affichent montants, énergies et variations (les 4 graisses de Poppins embarquées).
const poppins = ['Regular', 'Medium', 'SemiBold', 'Bold'];

void main() {
  final fonts = {
    for (final weight in poppins)
      'Poppins-$weight': FontCharacters.load('assets/fonts/Poppins-$weight.ttf'),
  };

  bool everyFontHas(int codePoint) => fonts.values.every((f) => f.has(codePoint));

  test('lecteur de police fiable (contrôles connus)', () {
    for (final font in fonts.values) {
      expect(font.has(0x41), isTrue, reason: 'A');
      expect(font.has(0xE9), isTrue, reason: 'é');
      expect(font.has(0x4E2D), isFalse, reason: 'idéogramme chinois');
    }
  });

  test(
    'séparateur des milliers : U+202F si Poppins la dessine, sinon l’espace insécable U+00A0',
    () {
      final expected = everyFontHas(0x202F) ? '\u202F' : '\u00A0';
      expect(groupSpace, expected);
      // Constat du 17/11/2026 : Poppins n'a PAS l'espace fine insécable.
      expect(everyFontHas(0x202F), isFalse);
    },
  );

  test('signe moins : U+2212 si Poppins le dessine, sinon le tiret classique', () {
    final expected = everyFontHas(0x2212) ? '\u2212' : '-';
    expect(minusSign, expected);
  });

  test('chaque caractère utilisé par les formats est dessiné par toutes les graisses', () {
    for (final char in [groupSpace, unitSpace, minusSign, enDash, '·', 'é', 'û', 'É']) {
      expect(
        everyFontHas(char.runes.single),
        isTrue,
        reason: 'U+${char.runes.single.toRadixString(16)}',
      );
    }
  });
}
