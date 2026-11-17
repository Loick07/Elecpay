import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Caractères invisibles (ou qui ressemblent à une espace normale) interdits « en dur » dans le code :
/// en relisant, on croirait voir une espace ordinaire, ou rien du tout. Il faut écrire leur code
/// d'échappement Dart (barre oblique inverse, « u », puis le numéro en 4 chiffres hexadécimaux) ;
/// les constantes prêtes à l'emploi sont dans `lib/core/format/typography.dart`.
/// Ce test ne contient lui-même que des numéros de caractères.
const forbidden = <int, String>{
  0x00A0: 'espace insécable',
  0x202F: 'espace fine insécable',
  0x2007: 'espace tabulaire',
  0x2009: 'espace fine',
  0x200A: 'espace ultra-fine',
  0x2002: 'demi-cadratin (espace)',
  0x2003: 'cadratin (espace)',
  0x3000: 'espace idéographique',
  0x00AD: 'trait d’union conditionnel',
  0x200B: 'espace de largeur nulle',
  0x200C: 'antiliant de largeur nulle',
  0x200D: 'liant de largeur nulle',
  0x2060: 'gluon de mots',
  0xFEFF: 'indicateur d’ordre des octets (BOM)',
};

void main() {
  test('aucun caractère invisible écrit en dur dans lib/, test/ et tool/', () {
    final problems = <String>[];
    for (final folder in ['lib', 'test', 'tool']) {
      final files = Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          for (final rune in lines[i].runes) {
            final name = forbidden[rune];
            if (name != null) {
              final code = rune.toRadixString(16).toUpperCase().padLeft(4, '0');
              problems.add('${file.path}:${i + 1} : $name (U+$code) → écrire son code');
            }
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('le contrôle repère bien un caractère interdit (contre-épreuve)', () {
    final sample =
        'const x = ${String.fromCharCode(39)}12${String.fromCharCode(0x00A0)}500${String.fromCharCode(39)};';
    expect(sample.runes.where(forbidden.containsKey), hasLength(1));
  });
}
