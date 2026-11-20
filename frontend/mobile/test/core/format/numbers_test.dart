import 'package:elecpay/core/format/numbers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rend les espaces insécables visibles (« · ») dans les attentes et les messages d'échec.
String visible(String s) => s.replaceAll('\u00A0', '·');

void main() {
  group('montants FCFA (entiers, jamais de centimes)', () {
    for (final (amount, expected) in [
      (0, '0·FCFA'),
      (7, '7·FCFA'),
      (999, '999·FCFA'),
      (1000, '1·000·FCFA'),
      (31420, '31·420·FCFA'),
      (40384, '40·384·FCFA'),
      (1250000, '1·250·000·FCFA'),
      (9007199254740991, '9·007·199·254·740·991·FCFA'),
      (-5000, '\u22125·000·FCFA'),
    ]) {
      test('$amount → $expected', () => expect(visible(formatFcfa(amount)), expected));
    }

    test('le nombre seul (montant héros, « FCFA » à part)', () {
      expect(visible(formatFcfaValue(31420)), '31·420');
    });

    test('l’unité ne se sépare jamais du nombre (espace insécable)', () {
      expect(formatFcfa(31420), isNot(contains(' ')));
    });
  });

  group('énergie (une décimale au plus, virgule)', () {
    for (final (kwh, expected) in [
      (417.4, '417,4·kWh'),
      (12.0, '12·kWh'),
      (12, '12·kWh'),
      (0, '0·kWh'),
      (0.04, '0·kWh'),
      (0.05, '0,1·kWh'),
      (321.45, '321,5·kWh'),
      (18664.4, '18·664,4·kWh'),
      (1234567.89, '1·234·567,9·kWh'),
      (-0.4, '\u22120,4·kWh'),
      (-12.3, '\u221212,3·kWh'),
    ]) {
      test('$kwh → $expected', () => expect(visible(formatKwh(kwh)), expected));
    }

    test('valeur sans unité (axes de graphique)', () {
      expect(visible(formatKwhValue(417.4)), '417,4');
    });
  });

  group('variations (signe, %, sens)', () {
    for (final (percent, text, trend) in [
      (-12, '\u221212·%', Trend.down),
      (-12.4, '\u221212·%', Trend.down),
      (-12.5, '\u221213·%', Trend.down),
      (8, '+8·%', Trend.up),
      (7.6, '+8·%', Trend.up),
      (0, '0·%', Trend.flat),
      (0.4, '0·%', Trend.flat),
      (-0.4, '0·%', Trend.flat),
      (150, '+150·%', Trend.up),
    ]) {
      test('$percent → $text ($trend)', () {
        final variation = formatVariation(percent);
        expect(visible(variation.text), text);
        expect(variation.trend, trend);
      });
    }
  });

  test('références : majuscules, sans espaces autour', () {
    expect(formatReference(' ep-2026-000123 '), 'EP-2026-000123');
    expect(formatReference('20261103000127'), '20261103000127');
  });

  test('estimations : « ≈ 206 kWh », « ≈ 10 100 FCFA » (arrondis honnêtes)', () {
    expect(visible(formatApproxKwh(206.3)), '≈·206·kWh');
    expect(visible(formatApproxKwh(1206.6)), '≈·1·207·kWh');
    expect(visible(formatApproxFcfa(10112)), '≈·10·100·FCFA');
    expect(visible(formatApproxFcfa(10150)), '≈·10·200·FCFA');
    expect(visible(formatApproxFcfa(40)), '≈·0·FCFA');
  });

  group('détail de facture (écran 7)', () {
    test('nombres d’affichage : « 49,08 », « 2 550 », « 417,4 »', () {
      expect(visible(formatDecimal(49.08)), '49,08');
      expect(visible(formatDecimal(2550.0)), '2·550');
      expect(visible(formatDecimal(417.4)), '417,4');
      expect(visible(formatDecimal(0.005)), '0,01');
      expect(visible(formatDecimal(12.3456, maxDecimals: 3)), '12,346');
    });

    test('taux : « 18 % », « 5 % », « 5,5 % »', () {
      expect(visible(formatPercent(18.0)), '18·%');
      expect(visible(formatPercent(5)), '5·%');
      expect(visible(formatPercent(5.5)), '5,5·%');
    });

    test('index : toujours au dixième, « 18 247,0 kWh »', () {
      expect(visible(formatIndexKwh(18247.0)), '18·247,0·kWh');
      expect(visible(formatIndexKwh(18664.44)), '18·664,4·kWh');
      expect(visible(formatIndexValue(18247)), '18·247,0');
    });

    test('variation à une décimale : « +0,6 % », « −2,5 % », « 0 % »', () {
      expect(visible(formatVariation(0.58, decimals: 1).text), '+0,6·%');
      expect(formatVariation(0.58, decimals: 1).trend, Trend.up);
      expect(visible(formatVariation(-2.46, decimals: 1).text), '−2,5·%');
      expect(formatVariation(0.02, decimals: 1).trend, Trend.flat);
      // Sans décimales : inchangé.
      expect(visible(formatVariation(0.58).text), '+1·%');
    });
  });

  test('coût d’énergie calculé : « ≈ 441 FCFA » (au franc près, jamais une facture)', () {
    expect(visible(formatAboutFcfa(441)), '≈·441·FCFA');
    expect(visible(formatAboutFcfa(10112)), '≈·10·112·FCFA');
  });
}
