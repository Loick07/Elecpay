import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
