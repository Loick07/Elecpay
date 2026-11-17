import 'package:elecpay/core/format/phone.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

BoxDecoration fieldBox(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;

void main() {
  const c = ElecPayColors.dark;

  testWidgets('libellé au-dessus, toujours visible (même pendant la saisie)', (tester) async {
    await pumpOnItel(tester, const AppTextField(label: 'Nom complet'));
    final label = tester.getRect(find.text('Nom complet'));
    final field = tester.getRect(find.byType(TextField));
    expect(label.bottom, lessThanOrEqualTo(field.top));
    await tester.enterText(find.byType(TextField), 'Grâce Ngoma');
    await tester.pump();
    expect(find.text('Nom complet'), findsOneWidget);
  });

  testWidgets('hauteur ≥ 52, fond surface-1, bordure line', (tester) async {
    await pumpOnItel(tester, const AppTextField(label: 'Nom'));
    expect(tester.getSize(find.byType(AnimatedContainer)).height, greaterThanOrEqualTo(52));
    final box = fieldBox(tester);
    expect(box.color, c.surface1);
    expect((box.border! as Border).top.color, c.line);
  });

  testWidgets('focus : bordure current et halo current-soft', (tester) async {
    await pumpOnItel(tester, const AppTextField(label: 'Nom'));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final box = fieldBox(tester);
    expect((box.border! as Border).top.color, c.current);
    expect(box.boxShadow!.single.color, c.currentSoft);
  });

  testWidgets('erreur : bordure error et message qui dit comment corriger', (tester) async {
    await pumpOnItel(
      tester,
      const AppTextField(label: 'Nom', helper: 'Votre nom complet', error: 'Nom trop court'),
    );
    expect((fieldBox(tester).border! as Border).top.color, c.error);
    expect(find.text('Nom trop court'), findsOneWidget);
    expect(find.text('Votre nom complet'), findsNothing, reason: 'l’erreur remplace l’aide');
    expect(tester.widget<Text>(find.text('Nom trop court')).style!.color, c.errorText);
  });

  testWidgets('mot de passe : caché, bouton pour l’afficher (zone tactile ≥ 48)', (tester) async {
    await pumpOnItel(tester, const AppTextField(label: 'Mot de passe', password: true));
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('référence : police mono', (tester) async {
    await pumpOnItel(tester, const AppTextField(label: 'N° de compteur', mono: true));
    expect(tester.widget<TextField>(find.byType(TextField)).style!.fontFamily, 'JetBrainsMono');
  });

  group('téléphone', () {
    String format(String typed) => CongoPhoneInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: typed))
        .text;

    test('regroupement automatique « 06 123 45 67 » pendant la saisie', () {
      expect(format('0'), '0');
      expect(format('06'), '06');
      expect(format('061'), '06 1');
      expect(format('06123'), '06 123');
      expect(format('061234'), '06 123 4');
      expect(format('0612345'), '06 123 45');
      expect(format('061234567'), '06 123 45 67');
    });

    test('9 chiffres au plus ; lettres et signes retirés', () {
      expect(format('0612345678999'), '06 123 45 67');
      expect(format('06a12-34'), '06 123 4');
    });

    test('numéro collé avec l’indicatif : ramené aux 9 chiffres', () {
      expect(format('+242 06 123 45 67'), '06 123 45 67');
      expect(format('00242061234567'), '06 123 45 67');
      expect(format('242061234567'), '06 123 45 67');
    });

    test('valeur pour l’API, mêmes règles que le backend', () {
      expect(PhoneField.normalized('06 123 45 67'), '+242061234567');
      expect(PhoneField.normalized('07 123 45 67'), isNull);
      expect(phoneError('07 123 45 67'), contains('04, 05, 06 ou 22'));
    });

    testWidgets('préfixe +242 fixe, clavier téléphone, saisie groupée', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpOnItel(tester, PhoneField(controller: controller));
      expect(find.text('+242'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).keyboardType, TextInputType.phone);
      await tester.enterText(find.byType(TextField), '061234567');
      expect(controller.text, '06 123 45 67');
      expect(PhoneField.normalized(controller.text), '+242061234567');
    });
  });

  group('écran de l’itel (360 × 800), texte agrandi', () {
    for (final scale in textScales) {
      testWidgets('texte × $scale : champs avec erreur longue, sans débordement', (tester) async {
        final controller = TextEditingController(text: '06 123 45 67');
        addTearDown(controller.dispose);
        await pumpOnItel(
          tester,
          Column(
            children: [
              PhoneField(
                controller: controller,
                error: 'Numéro invalide : il doit commencer par 04, 05, 06 ou 22',
              ),
              const SizedBox(height: Space.s4),
              const AppTextField(
                label: 'Mot de passe',
                password: true,
                helper: '8 caractères minimum, dont au moins un chiffre et une lettre',
              ),
            ],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
