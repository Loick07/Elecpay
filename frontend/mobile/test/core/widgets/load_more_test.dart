import 'dart:io';

import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/load_more.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpFooter(
  WidgetTester tester, {
  required bool failed,
  required VoidCallback onLoad,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: LoadMoreFooter(failed: failed, onLoad: onLoad),
    ),
  ),
);

void main() {
  testWidgets('construit : demande la page suivante une seule fois', (tester) async {
    var calls = 0;
    await pumpFooter(tester, failed: false, onLoad: () => calls++);
    await tester.pump();
    await tester.pump();
    expect(calls, 1);
    expect(find.bySemanticsLabel('Chargement de la suite'), findsOneWidget);
  });

  testWidgets('échec : aucune relance automatique, « Réessayer » relance', (tester) async {
    var calls = 0;
    await pumpFooter(tester, failed: true, onLoad: () => calls++);
    await tester.pump();
    expect(calls, 0);
    await tester.tap(find.text('Impossible de charger la suite. Réessayer'));
    expect(calls, 1);
    expect(
      tester.getSize(find.byKey(const Key('loadMore.retry'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  // Ajout de Loick (rapport de F5) : un seul composant pour toutes les listes paginées.
  test('un seul bas de liste paginée : aucune copie dans les écrans', () {
    final copies = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('load_more.dart')) continue;
      final text = file.readAsStringSync();
      if (text.contains('Impossible de charger la suite') ||
          text.contains("'Chargement de la suite'")) {
        copies.add(file.path);
      }
    }
    expect(copies, isEmpty);
  });
}
