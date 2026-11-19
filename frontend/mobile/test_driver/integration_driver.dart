// Côté PC des tests de parcours (integration_test/*_flows_test.dart) : range les captures prises
// sur le téléphone dans build/integration/<nom>.png, même quand un test échoue.
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final shots = (data?['screenshots'] as List<dynamic>?) ?? const [];
    for (final shot in shots.cast<Map<String, dynamic>>()) {
      final file = File('build/integration/${shot['screenshotName']}.png');
      await file.create(recursive: true);
      await file.writeAsBytes((shot['bytes'] as List<dynamic>).cast<int>());
    }
    stdout.writeln('${shots.length} capture(s) dans build/integration/');
  },
);
