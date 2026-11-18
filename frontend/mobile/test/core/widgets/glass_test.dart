import 'dart:io';
import 'dart:ui';

import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

/// Les seuls fichiers qui ont le droit d'utiliser `GlassSurface` : la barre du bas et les feuilles
/// du bas (F2.4, F2.5). Toute autre utilisation fait échouer le test.
const glassAllowed = {
  'lib/core/widgets/glass.dart',
  'lib/core/widgets/bottom_nav.dart',
  'lib/core/widgets/bottom_sheet.dart',
};

Widget sample() => const GlassSurface(
  borderRadius: BorderRadius.all(Radius.circular(Radii.xl)),
  child: SizedBox(width: 200, height: 60, child: Text('Barre')),
);

DecoratedBox innerDecoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .firstWhere((box) => (box.decoration as BoxDecoration).border != null);

void main() {
  /// L'option « Effet verre » activée (le flou n'est plus le réglage par défaut).
  final withBlur = [glassModeProvider.overrideWithBuild((ref, notifier) => GlassMode.blur)];

  testWidgets('par défaut (jalon F3) : AUCUN flou, fond opaque surface-2, bordure verre', (
    tester,
  ) async {
    await pumpOnItel(tester, sample());
    expect(find.byType(BackdropFilter), findsNothing);
    final decoration = innerDecoration(tester).decoration as BoxDecoration;
    expect(decoration.color, ElecPayColors.dark.surface2);
    expect(decoration.color!.a, 1.0, reason: 'fond opaque');
    expect(decoration.border, Border.all(color: ElecPayColors.dark.glassBorder));
  });

  testWidgets('option « Effet verre » : flou d’arrière-plan (sigma 12) et couleur verre', (
    tester,
  ) async {
    await pumpOnItel(tester, sample(), overrides: withBlur);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, ImageFilter.blur(sigmaX: Blur.glassSigma, sigmaY: Blur.glassSigma));
    final decoration = innerDecoration(tester).decoration as BoxDecoration;
    expect(decoration.color, ElecPayColors.dark.glass);
    expect(decoration.border, Border.all(color: ElecPayColors.dark.glassBorder));
  });

  testWidgets('contraste élevé demandé par le téléphone : sans flou, même avec l’option', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures.allOn;
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpOnItel(tester, sample(), overrides: withBlur);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  test('le réglage se change et se lit (sans flou au départ)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(glassModeProvider), GlassMode.opaque);
    container.read(glassModeProvider.notifier).set(GlassMode.blur);
    expect(container.read(glassModeProvider), GlassMode.blur);
    container.read(glassModeProvider.notifier).set(GlassMode.opaque);
    expect(container.read(glassModeProvider), GlassMode.opaque);
  });

  test('verre réservé à la barre du bas et aux feuilles ; aucun flou ailleurs', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (source.contains('GlassSurface(') && !glassAllowed.contains(path)) {
        offenders.add('$path : GlassSurface');
      }
      if (source.contains('BackdropFilter(') && path != 'lib/core/widgets/glass.dart') {
        offenders.add('$path : BackdropFilter');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
