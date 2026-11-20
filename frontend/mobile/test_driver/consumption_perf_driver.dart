// Côté PC de integration_test/consumption_perf_test.dart : enregistre les temps d'image du
// téléphone pour l'écran Consommation (graphiques fl_chart).
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final file = File('build/perf_conso.json');
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln('Temps d’image enregistrés dans ${file.path}');
  },
);
