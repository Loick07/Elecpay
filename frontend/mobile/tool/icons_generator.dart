// Génère lib/core/theme/lucide_icons.g.dart : le code (point de code de la police) de chaque icône
// Lucide utilisée par l'application, lu dans la table officielle tool/lucide/info.json.
//
// Ajouter une icône : l'ajouter à [lucideIcons] ci-dessous, puis `dart run tool/generate_icons.dart`.
// Un test vérifie que le fichier généré est à jour, et que chaque icône existe dans la police.

import 'dart:convert';

import 'package:dart_style/dart_style.dart';

/// Version de la police embarquée (paquet npm officiel `lucide-static`, licence ISC).
/// Changer de version : remplacer assets/fonts/Lucide.ttf ET tool/lucide/info.json, puis régénérer.
const lucideVersion = '1.73.0';

/// Famille de police déclarée dans pubspec.yaml.
const lucideFontFamily = 'Lucide';

/// Icônes utilisées : nom Dart → nom Lucide (https://lucide.dev/icons/). Seules celles-ci sont
/// générées ; Flutter ne garde dans l'APK que les icônes réellement utilisées dans le code.
const lucideIcons = <String, String>{
  'ban': 'ban',
  'check': 'check',
  'circleAlert': 'circle-alert',
  'circleQuestionMark': 'circle-question-mark',
  'clock': 'clock',
  'eye': 'eye',
  'eyeOff': 'eye-off',
  'fileText': 'file-text',
  'gauge': 'gauge',
  'hourglass': 'hourglass',
  'house': 'house',
  'inbox': 'inbox',
  'info': 'info',
  'lock': 'lock',
  'logIn': 'log-in',
  'refreshCw': 'refresh-cw',
  'shieldCheck': 'shield-check',
  'smartphone': 'smartphone',
  'timerOff': 'timer-off',
  'triangleAlert': 'triangle-alert',
  'wifiOff': 'wifi-off',
  'x': 'x',
  'zap': 'zap',
};

/// Point de code d'une icône de info.json (`"encodedCode": "\\e087"` → 0xe087).
int codePointOf(Map<String, dynamic> info, String lucideName) {
  final entry = info[lucideName];
  if (entry == null) {
    throw ArgumentError('Icône Lucide inconnue dans info.json ($lucideVersion) : $lucideName');
  }
  final encoded = (entry as Map<String, dynamic>)['encodedCode'] as String;
  return int.parse(encoded.replaceAll(RegExp(r'[^0-9a-fA-F]'), ''), radix: 16);
}

/// Contenu du fichier lib/core/theme/lucide_icons.g.dart.
String generateIcons(String infoJson) {
  final info = jsonDecode(infoJson) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln('// FICHIER GÉNÉRÉ par tool/generate_icons.dart depuis tool/lucide/info.json')
    ..writeln('// (lucide-static $lucideVersion). Ne pas modifier à la main.')
    ..writeln()
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln()
    ..writeln('/// Police des icônes (assets/fonts/Lucide.ttf, licence ISC + MIT).')
    ..writeln("const lucideFontFamily = '$lucideFontFamily';")
    ..writeln()
    ..writeln('/// Version de la police embarquée.')
    ..writeln("const lucideVersion = '$lucideVersion';")
    ..writeln()
    ..writeln('/// Icônes Lucide utilisées par l’application (passer par `AppIcons`).')
    ..writeln('abstract final class Lucide {');
  final names = lucideIcons.keys.toList()..sort();
  for (final name in names) {
    final lucideName = lucideIcons[name]!;
    final code = codePointOf(info, lucideName).toRadixString(16);
    out
      ..writeln('  /// `$lucideName`')
      ..writeln('  static const $name = IconData(0x$code, fontFamily: lucideFontFamily);');
  }
  out.writeln('}');
  return DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
    pageWidth: 100,
  ).format(out.toString());
}
