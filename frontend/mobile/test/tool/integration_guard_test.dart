// Garde-fou de tool/integration.ps1 (jalon F10, demande de Loick) : ce script SUPPRIME puis RECRÉE une
// base ; il doit refuser toute autre base que `elecpay_e2e` de ce PC. Le vrai script est lancé avec
// -CheckOnly : il s'arrête juste après le garde-fou, sans rien toucher (ni Docker, ni base, ni API).
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PowerShell : Windows PowerShell sur le PC de Loick, PowerShell 7 (`pwsh`) sur les serveurs de CI.
String? findPowerShell() {
  for (final exe in [if (Platform.isWindows) 'powershell', 'pwsh']) {
    try {
      final result = Process.runSync(exe, ['-NoProfile', '-Command', 'exit 0']);
      if (result.exitCode == 0) return exe;
    } on ProcessException {
      // Pas installé : essayer le suivant.
    }
  }
  return null;
}

final shell = findPowerShell();

ProcessResult guard({String? databaseUrl}) => Process.runSync(shell!, [
  '-NoProfile',
  '-ExecutionPolicy',
  'Bypass',
  '-File',
  'tool/integration.ps1',
  '-Device',
  'aucun-telephone',
  '-CheckOnly',
  if (databaseUrl != null) ...['-DatabaseUrl', databaseUrl],
]);

const prefix = 'mysql+pymysql://elecpay:elecpay@127.0.0.1:3307';

void main() {
  group('integration.ps1 : seule la base elecpay_e2e de ce PC', () {
    test('adresse par défaut : acceptée', () {
      final result = guard();
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      // Sans accent : la console Windows les abîme (« accept‚e »).
      expect('${result.stdout}', contains('Garde-fou : base elecpay_e2e accept'));
    });

    test('elecpay_e2e sur localhost : acceptée', () {
      final result = guard(
        databaseUrl: '$prefix/elecpay_e2e?charset=utf8mb4'.replaceFirst('127.0.0.1', 'localhost'),
      );
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });

    for (final (why, url) in [
      ('base de démo', '$prefix/elecpay?charset=utf8mb4'),
      ('base des tests du backend', '$prefix/elecpay_test'),
      (
        'nom caché dans les paramètres (accepté par l’ancienne règle)',
        '$prefix/elecpay?x=/elecpay_e2e',
      ),
      ('nom qui commence pareil', '$prefix/elecpay_e2e_bis'),
      ('majuscules', '$prefix/ELECPAY_E2E'),
      ('chemin après le nom', '$prefix/elecpay_e2e/../elecpay'),
      ('autre machine', 'mysql+pymysql://elecpay:elecpay@10.0.0.5:3307/elecpay_e2e'),
      ('autre moteur', 'sqlite:///elecpay_e2e'),
      ('adresse vide', ''),
    ]) {
      test('refusée : $why', () {
        final result = guard(databaseUrl: url);
        expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
        expect('${result.stdout}', contains('Refus'));
      });
    }
  }, skip: shell == null ? 'PowerShell introuvable sur cette machine' : null);
}
