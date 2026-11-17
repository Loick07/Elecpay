import 'dart:io';

import 'package:elecpay/app/licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(LicenseRegistry.reset);

  test('les fichiers de licence sont déclarés comme ressources de l’application', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final path in fontLicenses.values) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains('- $path'), reason: path);
    }
  });

  test('licences des polices visibles dans l’écran des licences', () async {
    LicenseRegistry.reset();
    registerFontLicenses(rootBundle);
    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String package) => entries
        .firstWhere((e) => e.packages.contains(package))
        .paragraphs
        .map((p) => p.text)
        .join('\n');

    final lucide = textOf('Lucide (icônes)');
    expect(lucide, contains('ISC License'));
    expect(lucide, contains('Lucide Icons and Contributors'));
    expect(lucide, contains('Feather'), reason: 'licence MIT des icônes issues de Feather');
    expect(textOf('Poppins'), contains('SIL OPEN FONT LICENSE'));
    expect(textOf('JetBrains Mono'), contains('SIL OPEN FONT LICENSE'));
  });
}
