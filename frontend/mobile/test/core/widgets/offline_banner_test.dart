import 'package:elecpay/core/cache/cached_api.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

void main() {
  final saved = DateTime.utc(2026, 11, 12, 7, 15);
  final cached = CachedData<int>(
    1,
    savedAt: saved,
    failure: const NoConnection(),
    shownAt: DateTime.utc(2026, 11, 17, 9),
  );

  testWidgets('donnée du cache : bannière en haut avec la date (texte de la charte)', (
    tester,
  ) async {
    await pumpOnItel(tester, OfflineBanner.forData(cached));
    expect(
      find.text('Hors connexion. Les données affichées datent du 12 nov. à 08:15.'),
      findsOneWidget,
    );
    final box = tester.widget<Container>(find.byType(Container).first);
    expect((box.decoration! as BoxDecoration).color, ElecPayColors.dark.warningSoft);
    expect(
      tester.widget<Text>(find.textContaining('Hors connexion')).style!.color,
      ElecPayColors.dark.warningText,
    );
  });

  testWidgets('donnée fraîche : aucune bannière', (tester) async {
    await pumpOnItel(tester, OfflineBanner.forData(const FreshData<int>(1)));
    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('annoncée au lecteur d’écran quand elle apparaît', (tester) async {
    await pumpOnItel(tester, OfflineBanner.forData(cached));
    expect(tester.getSemantics(find.byType(OfflineBanner)).flagsCollection.isLiveRegion, isTrue);
  });

  for (final scale in textScales) {
    testWidgets('texte × $scale : sans débordement sur l’itel', (tester) async {
      await pumpOnItel(tester, OfflineBanner.forData(cached), textScale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
