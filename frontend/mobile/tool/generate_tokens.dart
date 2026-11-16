// Régénère lib/core/theme/tokens.g.dart depuis la charte. Depuis frontend/mobile/ :
//     dart run tool/generate_tokens.dart

import 'dart:io';

import 'tokens_generator.dart';

const tokensPath = '../design/tokens.json';
const outputPath = 'lib/core/theme/tokens.g.dart';

void main() {
  final code = generateTokens(File(tokensPath).readAsStringSync());
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(code);
  stdout.writeln('Écrit : $outputPath (${code.split('\n').length} lignes)');
}
