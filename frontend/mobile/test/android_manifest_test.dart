import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/apk_check.dart' show dataDomains, extractionSections;

/// Le HTTP en clair n'est permis QUE dans les versions de développement (debug, profile) ;
/// la version livrée parle à l'API en HTTPS seulement, et a bien le droit d'accéder à Internet.
void main() {
  String manifest(String sourceSet) =>
      File('android/app/src/$sourceSet/AndroidManifest.xml').readAsStringSync();

  test('version livrée : Internet autorisé, HTTP en clair interdit', () {
    final main = manifest('main');
    expect(main, contains('android.permission.INTERNET'));
    expect(main, contains('android:usesCleartextTraffic="false"'));
    expect(main, isNot(contains('android:usesCleartextTraffic="true"')));
  });

  test('aucune sauvegarde Android (jetons et cache), et aucune version ne la réactive', () {
    expect(manifest('main'), contains('android:allowBackup="false"'));
    for (final sourceSet in ['debug', 'profile']) {
      expect(manifest(sourceSet), isNot(contains('allowBackup')));
    }
  });

  group('règles d’extraction de données (Android 12+)', () {
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();

    /// Contenu d'une section (`<cloud-backup>…</cloud-backup>`), sans les commentaires.
    String section(String name) {
      final match = RegExp('<$name>(.*?)</$name>', dotAll: true).firstMatch(rules);
      expect(match, isNotNull, reason: 'section <$name> absente');
      return match!.group(1)!.replaceAll(RegExp('<!--.*?-->', dotAll: true), '');
    }

    test('le manifeste y fait référence', () {
      expect(
        manifest('main'),
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      for (final sourceSet in ['debug', 'profile']) {
        expect(manifest(sourceSet), isNot(contains('dataExtractionRules')));
      }
    });

    for (final name in extractionSections) {
      test('<$name> exclut TOUS les domaines en entier, sans aucune inclusion', () {
        final content = section(name);
        expect(content, isNot(contains('<include')));
        final excluded = {
          for (final m in RegExp(r'<exclude domain="(\w+)" path="\."\s*/>').allMatches(content))
            m.group(1),
        };
        expect(excluded, dataDomains.toSet());
        // Aucune autre règle que ces exclusions complètes.
        expect(RegExp('<exclude').allMatches(content), hasLength(dataDomains.length));
      });
    }
  });

  for (final sourceSet in ['debug', 'profile']) {
    test('$sourceSet : HTTP en clair permis (API locale du PC)', () {
      expect(manifest(sourceSet), contains('android:usesCleartextTraffic="true"'));
    });
  }

  test('identifiant et version minimale d’Android', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "cg.elecpay.client"'));
    expect(gradle, contains('minSdk = 24'));
  });
}
