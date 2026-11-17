import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:elecpay/core/format/numbers.dart';
import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

Material materialOf(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
);

void main() {
  final pay = 'Payer ${formatFcfa(31420)}';

  group('variantes de la charte', () {
    for (final (variant, background, foreground) in [
      (ButtonVariant.primary, ElecPayColors.dark.volt, ElecPayColors.dark.onVolt),
      (ButtonVariant.secondary, ElecPayColors.dark.surface2, ElecPayColors.dark.ink),
      (ButtonVariant.ghost, Colors.transparent, ElecPayColors.dark.voltText),
      (ButtonVariant.danger, ElecPayColors.dark.errorSoft, ElecPayColors.dark.errorText),
    ]) {
      testWidgets('$variant : fond et texte', (tester) async {
        await pumpOnItel(tester, AppButton(label: 'Action', variant: variant, onPressed: () {}));
        expect(materialOf(tester).color, background);
        expect(tester.widget<Text>(find.text('Action')).style!.color, foreground);
      });
    }

    testWidgets('secondaire : surface opaque, PAS de verre (réservé barre du bas / feuilles)', (
      tester,
    ) async {
      await pumpOnItel(
        tester,
        AppButton(label: 'Télécharger le reçu', variant: ButtonVariant.secondary, onPressed: () {}),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  testWidgets('zone tactile ≥ 48 × 48 et libellé lu par le lecteur d’écran', (tester) async {
    await pumpOnItel(tester, AppButton(label: 'OK', onPressed: () {}));
    final size = tester.getSize(find.byType(AppButton));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester.getSemantics(find.byType(AppButton)).label, 'OK');
  });

  testWidgets('désactivé : opacité 45 %, rien ne se passe', (tester) async {
    await pumpOnItel(tester, const AppButton(label: 'Payer', onPressed: null));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0.45);
    await tester.tap(find.byType(AppButton));
    expect(tester.getSemantics(find.byType(AppButton)).flagsCollection.isEnabled, Tristate.isFalse);
  });

  group('chargement (protection contre le double paiement)', () {
    testWidgets('chargement imposé : indicateur, libellé de chargement, plus cliquable', (
      tester,
    ) async {
      var taps = 0;
      await pumpOnItel(
        tester,
        AppButton(
          label: pay,
          icon: AppIcons.check,
          loading: true,
          loadingLabel: 'Paiement en cours…',
          onPressed: () => taps++,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsNothing, reason: 'l’indicateur remplace l’icône');
      expect(find.text('Paiement en cours…'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });

    testWidgets('action asynchrone : un double toucher ne lance qu’UNE action', (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await pumpOnItel(
        tester,
        AppButton(
          label: pay,
          loadingLabel: 'Paiement en cours…',
          onPressed: () {
            calls++;
            return pending.future;
          },
        ),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(calls, 1);
      expect(find.text('Paiement en cours…'), findsOneWidget);

      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text(pay), findsOneWidget, reason: 'de nouveau disponible après l’action');
      await tester.tap(find.byType(AppButton));
      expect(calls, 2);
    });

    testWidgets('la taille ne change pas pendant le chargement', (tester) async {
      Widget button({required bool loading}) => SizedBox(
        width: 328,
        child: AppButton(label: pay, loading: loading, onPressed: () {}),
      );
      await pumpOnItel(tester, button(loading: false));
      final before = tester.getSize(find.byType(AppButton));
      await pumpOnItel(tester, button(loading: true));
      expect(tester.getSize(find.byType(AppButton)).height, before.height);
    });
  });

  group('écran de l’itel (360 × 800), texte agrandi', () {
    for (final scale in textScales) {
      testWidgets('texte × $scale : long libellé sans débordement', (tester) async {
        await pumpOnItel(
          tester,
          Column(
            children: [
              AppButton(label: 'Payer ${formatFcfa(1250000)} pour Maison Mpita', onPressed: () {}),
              const SizedBox(height: Space.s3),
              AppButton(
                label: 'Télécharger le reçu',
                icon: AppIcons.check,
                variant: ButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('thème Jour aussi', (tester) async {
      await pumpOnItel(
        tester,
        AppButton(label: pay, onPressed: () {}),
        theme: AppTheme.light,
      );
      expect(materialOf(tester).color, ElecPayColors.light.volt);
    });
  });
}
