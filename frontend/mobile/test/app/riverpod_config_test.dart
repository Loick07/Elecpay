import 'dart:io';

import 'package:elecpay/app/riverpod_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Riverpod 3 relance par défaut une lecture en échec jusqu'à 10 fois (≈ 45 s « en chargement ») :
/// ElecPay ne relance JAMAIS automatiquement (règle de F1, défaut vu en F4.1).
void main() {
  test('la règle : jamais de relance, quelle que soit l’erreur', () {
    for (final count in [0, 1, 9]) {
      expect(noAutomaticRetry(count, Exception('hors ligne')), isNull);
    }
  });

  test('tout conteneur Riverpod de l’application et des tests sur le téléphone l’applique', () {
    final sources = [
      for (final dir in ['lib', 'integration_test'])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')),
    ];
    final offenders = <String>[];
    var containers = 0;
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final match in RegExp(r'\b(ProviderScope|ProviderContainer)\(').allMatches(text)) {
        containers++;
        // Les arguments du constructeur (jusqu'à la fin de la ligne suivante suffisent ici).
        final call = text.substring(match.start, (match.end + 160).clamp(0, text.length));
        if (!call.contains('retry: noAutomaticRetry')) {
          offenders.add('${file.path.replaceAll(r'\', '/')} : ${match.group(1)}');
        }
      }
    }
    expect(containers, greaterThan(0), reason: 'le test doit trouver lib/main.dart');
    expect(offenders, isEmpty);
  });
}
