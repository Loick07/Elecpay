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

/// Sens d'une variation (la couleur en dépend : baisse = vert, hausse = orange).
enum Trend { down, flat, up }

/// Variation affichée : texte et sens.
typedef Variation = ({String text, Trend trend});

/// Variation en pourcentage, arrondie à l'entier : −12.4 → « −12 % » (baisse) ; 8 → « +8 % » ;
/// 0.3 → « 0 % » (stable).
Variation formatVariation(num percent) {
  final rounded = percent.round();
  if (rounded == 0) return (text: '0$unitSpace%', trend: Trend.flat);
  return rounded < 0
      ? (text: '$minusSign${-rounded}$unitSpace%', trend: Trend.down)
      : (text: '+$rounded$unitSpace%', trend: Trend.up);
}

/// Référence (facture, transaction, reçu, compteur) : majuscules, sans espaces autour.
/// L'affichage en police mono est fait par le style `AppText.reference`.
String formatReference(String reference) => reference.trim().toUpperCase();
