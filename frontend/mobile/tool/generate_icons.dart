// Régénère lib/core/theme/lucide_icons.g.dart depuis tool/lucide/info.json. Depuis frontend/mobile/ :
//     dart run tool/generate_icons.dart

import 'dart:io';

import 'icons_generator.dart';

const infoPath = 'tool/lucide/info.json';
const outputPath = 'lib/core/theme/lucide_icons.g.dart';

void main() {
  final code = generateIcons(File(infoPath).readAsStringSync());
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(code);
  stdout.writeln(
    'Écrit : $outputPath (${lucideIcons.length} icônes, lucide-static $lucideVersion)',
  );
}
