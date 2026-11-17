import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

/// Le constructeur de skeletonizer crée une sous-classe privée : on cherche « est un Skeletonizer ».
final skeletonizer = find.byWidgetPredicate((widget) => widget is Skeletonizer);

const card = AppSkeleton(
  loading: true,
  child: ListTile(title: Text('Maison Mpita'), subtitle: Text('31 420 FCFA')),
);

void main() {
  testWidgets('chargement : squelette posé sur le vrai widget, pulsation 1,4 s en surface-3', (
    tester,
  ) async {
    await tester.pumpWidget(app(card));
    final skeleton = tester.widget<Skeletonizer>(skeletonizer);
    expect(skeleton.enabled, isTrue);
    final effect = skeleton.effect! as PulseEffect;
    expect(effect.from, ElecPayColors.dark.surface3);
    expect(effect.duration, const Duration(milliseconds: 1400));
    expect(tester.getSemantics(find.byType(AppSkeleton)).label, contains('Chargement'));
  });

  testWidgets('animations réduites : formes fixes, sans pulsation', (tester) async {
    await tester.pumpWidget(app(card, reduceMotion: true));
    final skeleton = tester.widget<Skeletonizer>(skeletonizer);
    expect(skeleton.effect, isA<SolidColorEffect>());
  });

  testWidgets('chargé : le contenu s’affiche normalement', (tester) async {
    await tester.pumpWidget(app(const AppSkeleton(loading: false, child: Text('Maison Mpita'))));
    expect(tester.widget<Skeletonizer>(skeletonizer).enabled, isFalse);
    expect(find.text('Maison Mpita'), findsOneWidget);
  });
}
