import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/form_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

void main() {
  const c = ElecPayColors.dark;

  testWidgets('erreur : fond error-soft, texte error-text, icône d’alerte, référence', (
    tester,
  ) async {
    await pumpOnItel(
      tester,
      const FormMessage('Numéro ou mot de passe incorrect.', reference: 'app-ref123456'),
    );
    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration! as BoxDecoration).color, c.errorSoft);
    expect(
      tester.widget<Text>(find.text('Numéro ou mot de passe incorrect.')).style!.color,
      c.errorText,
    );
    expect(find.byIcon(AppIcons.error), findsOneWidget);
    expect(find.text('Référence : app-ref123456'), findsOneWidget);
  });

  testWidgets('information (code de démo) : fond current-soft, icône info', (tester) async {
    await pumpOnItel(
      tester,
      const FormMessage('Mode démo : votre code est 482 913.', tone: FormMessageTone.info),
    );
    final box = tester.widget<Container>(find.byType(Container));
    expect((box.decoration! as BoxDecoration).color, c.currentSoft);
    expect(find.byIcon(AppIcons.info), findsOneWidget);
  });

  testWidgets('annoncé au lecteur d’écran dès qu’il apparaît', (tester) async {
    await pumpOnItel(tester, const FormMessage('Erreur.'));
    expect(tester.getSemantics(find.byType(FormMessage)).flagsCollection.isLiveRegion, isTrue);
  });

  for (final scale in textScales) {
    testWidgets('texte × $scale : long message sans débordement', (tester) async {
      await pumpOnItel(
        tester,
        const FormMessage(
          'Ce compte est réservé à l’équipe ElecPay : connectez-vous depuis le back-office.',
          reference: 'app-k3v9q2x7m1z8c4b6n0p5',
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
