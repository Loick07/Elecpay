/// Montants, énergie et variations, au format de la charte (`frontend/design/CHARTE.md`).
library;

import 'typography.dart';

/// Chiffres groupés par milliers : 1234567 → « 1 234 567 » (espace insécable).
String _group(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(groupSpace);
    out.write(digits[i]);
  }
  return '${value < 0 ? minusSign : ''}$out';
}

/// Montant en FCFA, toujours entier : 31420 → « 31 420 FCFA ». Jamais de centimes.
String formatFcfa(int amount) => '${formatFcfaValue(amount)}${unitSpace}FCFA';

/// Le nombre seul, quand « FCFA » est écrit à part en plus petit (montant héros) : « 31 420 ».
String formatFcfaValue(int amount) => _group(amount);

/// Nombre de kWh (sans l'unité), une décimale au plus, virgule : 417.4 → « 417,4 » ;
/// 12.0 → « 12 » ; 18664.4 → « 18 664,4 ». Arrondi au dixième le plus proche.
String formatKwhValue(num kwh) {
  final tenths = (kwh * 10).round();
  final whole = tenths ~/ 10;
  // `remainder`, pas `%` : en Dart, -4 % 10 vaut 6 (modulo toujours positif).
  final decimal = tenths.remainder(10).abs();
  final sign = tenths < 0 && whole == 0 ? minusSign : '';
  return '$sign${_group(whole)}${decimal == 0 ? '' : ',$decimal'}';
}

/// Énergie : « 417,4 kWh ».
String formatKwh(num kwh) => '${formatKwhValue(kwh)}${unitSpace}kWh';

/// Signe d'une valeur approchée (estimation).
const _approx = '≈';

/// Énergie ESTIMÉE, arrondie au kWh : 206.3 → « ≈ 206 kWh ».
String formatApproxKwh(num kwh) => '$_approx$unitSpace${_group(kwh.round())}${unitSpace}kWh';

/// Montant ESTIMÉ, arrondi à la centaine : 10112 → « ≈ 10 100 FCFA ». Une estimation n'affiche
/// jamais une précision qu'elle n'a pas.
String formatApproxFcfa(int amount) =>
    '$_approx$unitSpace${formatFcfa(((amount / 100).round()) * 100)}';

/// Coût d'énergie calculé (kWh × tarif, sans taxes) : « ≈ 441 FCFA ». Le « ≈ » rappelle que ce
/// n'est pas une facture (seule la facture bimestrielle E²C fait foi).
String formatAboutFcfa(int amount) => '$_approx$unitSpace${formatFcfa(amount)}';

/// Nombre décimal d'AFFICHAGE (prix unitaire, quantité), au plus `maxDecimals` décimales utiles,
/// virgule : 49.08 → « 49,08 » ; 2550.0 → « 2 550 » ; 417.4 → « 417,4 ». Jamais pour un montant
/// (les montants sont des FCFA entiers : `formatFcfa`).
String formatDecimal(num value, {int maxDecimals = 2}) {
  var scale = 1;
  for (var i = 0; i < maxDecimals; i++) {
    scale *= 10;
  }
  final scaled = (value * scale).round();
  final whole = scaled ~/ scale;
  var decimals = scaled.remainder(scale).abs().toString().padLeft(maxDecimals, '0');
  while (decimals.endsWith('0')) {
    decimals = decimals.substring(0, decimals.length - 1);
  }
  final sign = scaled < 0 && whole == 0 ? minusSign : '';
  return '$sign${_group(whole)}${decimals.isEmpty ? '' : ',$decimals'}';
}

/// Puissance (onglet Direct), toujours au centième : 1.234 → « 1,23 » ; 0.5 → « 0,50 ».
String formatKwValue(double kw) {
  final hundredths = (kw * 100).round();
  return '${_group(hundredths ~/ 100)},${hundredths.remainder(100).abs().toString().padLeft(2, '0')}';
}

/// Puissance avec son unité : « 1,23 kW ».
String formatKw(double kw) => '${formatKwValue(kw)}${unitSpace}kW';

/// Pour TalkBack : unités d'énergie et de puissance en toutes lettres. « 19,3 kWh » était lu
/// « 19.3 KWAT » sur l'itel (jalon F4 → F7) ; l'écran, lui, garde « kWh ». Singulier sous 2
/// (« 0 kilowattheure », « 1,5 kilowattheure »), pluriel au-delà.
String spokenUnits(String text) => text.replaceAllMapped(
  RegExp(
    '([0-9][0-9\u00A0]*(?:,[0-9]+)?)\u00A0(kWh|kW|kVA)'
    r'\b',
  ),
  (m) {
    final value = double.parse(m[1]!.replaceAll(groupSpace, '').replaceAll(',', '.'));
    final word = switch (m[2]) {
      'kWh' => 'kilowattheure',
      'kW' => 'kilowatt',
      _ => 'kilovoltampère',
    };
    return '${m[1]} $word${value.abs() < 2 ? '' : 's'}';
  },
);

/// Taux : 18.0 → « 18 % » ; 5.5 → « 5,5 % ».
String formatPercent(num percent) => '${formatDecimal(percent)}$unitSpace%';

/// Index de compteur, toujours au dixième (maquette de l'écran 7) : 18247.0 → « 18 247,0 kWh ».
String formatIndexKwh(num kwh) => '${formatIndexValue(kwh)}${unitSpace}kWh';

/// Index seul, au dixième (liste « Jour par jour » : « Index 18 247,0 – 18 256,0 »).
String formatIndexValue(num kwh) {
  final tenths = (kwh * 10).round();
  return '${_group(tenths ~/ 10)},${tenths.remainder(10).abs()}';
}

/// Sens d'une variation (la couleur en dépend : baisse = vert, hausse = orange).
enum Trend { down, flat, up }

/// Variation affichée : texte et sens.
typedef Variation = ({String text, Trend trend});

/// Variation en pourcentage, arrondie à l'entier : −12.4 → « −12 % » (baisse) ; 8 → « +8 % » ;
/// 0.3 → « 0 % » (stable).
///
/// `decimals: 1` (comparaison de deux factures, maquette de l'écran 7) : 0.58 → « +0,6 % ».
Variation formatVariation(num percent, {int decimals = 0}) {
  if (decimals > 0) {
    final text = formatDecimal(percent.abs(), maxDecimals: decimals);
    if (text == '0') return (text: '0$unitSpace%', trend: Trend.flat);
    return percent < 0
        ? (text: '$minusSign$text$unitSpace%', trend: Trend.down)
        : (text: '+$text$unitSpace%', trend: Trend.up);
  }
  final rounded = percent.round();
  if (rounded == 0) return (text: '0$unitSpace%', trend: Trend.flat);
  return rounded < 0
      ? (text: '$minusSign${-rounded}$unitSpace%', trend: Trend.down)
      : (text: '+$rounded$unitSpace%', trend: Trend.up);
}

/// Référence (facture, transaction, reçu, compteur) : majuscules, sans espaces autour.
/// L'affichage en police mono est fait par le style `AppText.reference`.
String formatReference(String reference) => reference.trim().toUpperCase();
