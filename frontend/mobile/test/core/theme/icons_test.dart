import 'dart:convert';
import 'dart:io';

import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/lucide_icons.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/icons_generator.dart' as generator;
import '../../support/font_cmap.dart';

/// Toutes les icônes de `AppIcons` (à compléter avec chaque nouvelle icône).
const appIcons = <String, IconData>{
  'clock': AppIcons.clock,
  'hourglass': AppIcons.hourglass,
  'check': AppIcons.check,
  'alert': AppIcons.alert,
  'cancelled': AppIcons.cancelled,
  'cross': AppIcons.cross,
  'expired': AppIcons.expired,
  'question': AppIcons.question,
  'show': AppIcons.show,
  'hide': AppIcons.hide,
  'phone': AppIcons.phone,
  'empty': AppIcons.empty,
  'error': AppIcons.error,
  'offline': AppIcons.offline,
  'locked': AppIcons.locked,
  'signIn': AppIcons.signIn,
  'retry': AppIcons.retry,
  'bill': AppIcons.bill,
  'energy': AppIcons.energy,
  'meter': AppIcons.meter,
  'household': AppIcons.household,
  'securePay': AppIcons.securePay,
  'info': AppIcons.info,
};

void main() {
  final info = File('tool/lucide/info.json').readAsStringSync();
  final font = FontCharacters.load('assets/fonts/Lucide.ttf');

  test('lucide_icons.g.dart est à jour avec tool/lucide/info.json', () {
    expect(
      File('lib/core/theme/lucide_icons.g.dart').readAsStringSync(),
      generator.generateIcons(info),
      reason: 'relancer : dart run tool/generate_icons.dart',
    );
  });

  test('chaque icône listée existe dans la table officielle ET dans la police embarquée', () {
    final table = jsonDecode(info) as Map<String, dynamic>;
    for (final MapEntry(key: name, value: lucideName) in generator.lucideIcons.entries) {
      expect(table.containsKey(lucideName), isTrue, reason: lucideName);
      final code = generator.codePointOf(table, lucideName);
      expect(font.has(code), isTrue, reason: '$name ($lucideName, U+${code.toRadixString(16)})');
    }
  });

  test('chaque icône de l’application est dessinée par la police Lucide embarquée', () {
    for (final MapEntry(key: name, value: icon) in appIcons.entries) {
      expect(icon.fontFamily, lucideFontFamily, reason: name);
      expect(icon.fontPackage, isNull, reason: '$name : police de l’application, pas d’un paquet');
      expect(font.has(icon.codePoint), isTrue, reason: name);
    }
  });

  test('version de la police : la même partout', () {
    expect(lucideVersion, generator.lucideVersion);
    expect(File('pubspec.yaml').readAsStringSync(), contains('lucide-static $lucideVersion'));
  });

  test('plus aucun paquet d’icônes (ses polices partaient entières dans l’APK)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('lucide_icons_flutter:')));
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.dart')) {
        expect(file.readAsStringSync(), isNot(contains('package:lucide_icons')), reason: file.path);
      }
    }
  });
}
