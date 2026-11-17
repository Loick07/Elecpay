import 'package:elecpay/core/format/numbers.dart';
import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/core/widgets/app_button.dart';
import 'package:elecpay/core/widgets/bill_row.dart';
import 'package:elecpay/core/widgets/hero_bill_card.dart';
import 'package:elecpay/core/widgets/pay_button.dart';
import 'package:elecpay/core/widgets/status_badge.dart';
import 'package:elecpay/core/widgets/statuses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

const c = ElecPayColors.dark;
final pay31420 = 'Payer ${formatFcfa(31420)}';

AppButton payButton(WidgetTester tester) => tester.widget<AppButton>(
  find.ancestor(of: find.text(pay31420), matching: find.byType(AppButton)),
);

HeroBillCard hero({DateTime? due, bool online = true, String? household, VoidCallback? onPay}) =>
    HeroBillCard(
      periodLabel: 'sept.–oct. 2026',
      status: billStatus('unpaid'),
      amount: 31420,
      dueDate: due ?? DateTime(2026, 11, 18),
      now: DateTime.utc(2026, 11, 12, 9),
      meterLabel: '0412-8833',
      consumptionKwh: 417.4,
      online: online,
      onDetail: () {},
      onPay: onPay ?? () {},
      householdName: household,
    );

void main() {
  group('badge de statut', () {
    testWidgets('une couleur, une icône ET un mot ; lu « Statut : … »', (tester) async {
      await pumpOnItel(tester, StatusBadge(billStatus('paid')));
      expect(find.text('Payée'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(tester.getSemantics(find.byType(StatusBadge)).label, 'Statut : Payée');
      final box = tester.widget<Container>(find.byType(Container));
      expect((box.decoration! as BoxDecoration).color, c.successSoft);
      expect(tester.widget<Text>(find.text('Payée')).style!.color, c.successText);
    });

    testWidgets('hauteur 26 au moins', (tester) async {
      await pumpOnItel(tester, Center(child: StatusBadge(billStatus('overdue'))));
      expect(tester.getSize(find.byType(StatusBadge)).height, greaterThanOrEqualTo(26));
    });
  });

  group('bouton Payer', () {
    testWidgets('en ligne : « Payer 31 420 FCFA », actif', (tester) async {
      var taps = 0;
      await pumpOnItel(tester, PayButton(amount: 31420, online: true, onPay: () => taps++));
      await tester.tap(find.text(pay31420));
      expect(taps, 1);
      expect(find.text(PayButton.offlineHint), findsNothing);
    });

    testWidgets('HORS LIGNE : désactivé, « Connexion nécessaire pour payer »', (tester) async {
      var taps = 0;
      await pumpOnItel(tester, PayButton(amount: 31420, online: false, onPay: () => taps++));
      expect(payButton(tester).onPressed, isNull);
      expect(find.text('Connexion nécessaire pour payer'), findsOneWidget);
      await tester.tap(find.text(pay31420));
      expect(taps, 0);
    });
  });

  group('ligne de facture', () {
    BillRow row({VoidCallback? onTap, String home = 'Maison Mpita'}) => BillRow(
      title: home,
      subtitle: '417,4 kWh · échéance le 18 nov.',
      amount: 31420,
      status: billStatus('unpaid'),
      onTap: onTap ?? () {},
    );

    testWidgets('foyer, ligne secondaire, montant et badge ; toute la ligne ouvre le détail', (
      tester,
    ) async {
      var opened = 0;
      await pumpOnItel(tester, row(onTap: () => opened++));
      expect(find.text('Maison Mpita'), findsOneWidget);
      expect(find.text('417,4 kWh · échéance le 18 nov.'), findsOneWidget);
      expect(find.text(formatFcfa(31420)), findsOneWidget);
      expect(find.text('À payer'), findsOneWidget);
      expect(tester.getSize(find.byType(BillRow)).height, greaterThanOrEqualTo(64));
      await tester.tap(find.byIcon(AppIcons.bill)); // même l'icône ouvre le détail
      expect(opened, 1);
      expect(
        tester.getSemantics(find.byType(BillRow)).label,
        'Maison Mpita, 417,4 kWh · échéance le 18 nov., ${formatFcfa(31420)}, À payer',
      );
    });

    testWidgets('groupe : titre en capitales et séparateur entre les lignes', (tester) async {
      await pumpOnItel(
        tester,
        BillRowGroup(
          title: 'Septembre – octobre 2026',
          rows: [
            row(),
            row(home: 'Boutique Tié-Tié'),
          ],
        ),
      );
      expect(find.text('SEPTEMBRE – OCTOBRE 2026'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('texte très agrandi : montant et badge passent sous le foyer', (tester) async {
      await pumpOnItel(tester, row(), textScale: 2);
      final home = tester.getRect(find.text('Maison Mpita'));
      final amount = tester.getRect(find.text(formatFcfa(31420)));
      expect(amount.top, greaterThan(home.bottom));
      expect(amount.left, home.left, reason: 'aligné sous le foyer');
    });

    testWidgets('texte normal : montant à droite, sur la ligne du foyer', (tester) async {
      await pumpOnItel(tester, row());
      final home = tester.getRect(find.text('Maison Mpita'));
      final amount = tester.getRect(find.text(formatFcfa(31420)));
      expect(amount.left, greaterThan(home.right));
    });

    for (final scale in textScales) {
      testWidgets('texte × $scale : sans débordement sur l’itel', (tester) async {
        await pumpOnItel(
          tester,
          BillRowGroup(
            title: 'Septembre – octobre 2026',
            rows: [row(home: 'Boutique Tié-Tié du marché Total')],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('carte de la facture urgente', () {
    testWidgets('ordre de lecture de la maquette : période, montant, échéance, compteur, boutons', (
      tester,
    ) async {
      await pumpOnItel(tester, hero());
      double top(Finder f) => tester.getTopLeft(f).dy;
      final period = find.text('FACTURE DE SEPT.–OCT. 2026');
      // « 31 420 » en grand puis « FCFA » en petit : un seul texte en deux morceaux.
      final amount = find.text(formatFcfa(31420), findRichText: true);
      final due = find.textContaining('Échéance le 18 nov. 2026', findRichText: true);
      final meter = find.text('Compteur 0412-8833');
      expect(period, findsOneWidget);
      expect(top(period), lessThan(top(amount)));
      expect(top(amount), lessThan(top(due)));
      expect(top(due), lessThan(top(meter)));
      expect(top(meter), lessThan(top(find.text(pay31420))));
      expect(find.text(formatKwh(417.4)), findsOneWidget);
      expect(find.text('Détail'), findsOneWidget);
    });

    testWidgets('opaque (pas de verre) : surface-1', (tester) async {
      await pumpOnItel(tester, hero());
      expect(find.byType(BackdropFilter), findsNothing);
    });

    for (final (due, text, color) in [
      (DateTime(2026, 11, 18), 'dans 6 jours', c.inkMuted),
      (DateTime(2026, 11, 15), 'dans 3 jours', c.warningText),
      (DateTime(2026, 11, 10), 'en retard de 2 jours', c.errorText),
    ]) {
      testWidgets('compte à rebours « $text » dans sa couleur', (tester) async {
        await pumpOnItel(tester, hero(due: due));
        final rich = tester.widget<RichText>(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Échéance le'),
          ),
        );
        TextSpan? countdown;
        rich.text.visitChildren((span) {
          if (span is TextSpan && span.text == text) countdown = span;
          return true;
        });
        expect(countdown, isNotNull, reason: rich.text.toPlainText());
        expect(countdown!.style!.color, color);
      });
    }

    testWidgets('plusieurs foyers : le nom du foyer dans le surtitre', (tester) async {
      await pumpOnItel(tester, hero(household: 'Maison Mpita'));
      expect(find.text('FACTURE DE SEPT.–OCT. 2026 · MAISON MPITA'), findsOneWidget);
    });

    testWidgets('hors ligne : Payer désactivé avec « Connexion nécessaire pour payer »', (
      tester,
    ) async {
      var paid = 0;
      await pumpOnItel(tester, hero(online: false, onPay: () => paid++));
      expect(payButton(tester).onPressed, isNull);
      expect(find.text(PayButton.offlineHint), findsOneWidget);
      await tester.tap(find.text(pay31420));
      expect(paid, 0);
    });

    testWidgets('tout est payé : « Tout est payé » et la prochaine facture', (tester) async {
      await pumpOnItel(tester, AllPaidCard(nextBillDate: DateTime(2027, 1, 3)));
      expect(find.text('Tout est payé'), findsOneWidget);
      expect(find.text('Prochaine facture prévue le 3 janv. 2027'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Tout est payé')).style!.color, c.successText);
    });

    for (final scale in textScales) {
      testWidgets('texte × $scale : en ligne et hors ligne, sans débordement sur l’itel', (
        tester,
      ) async {
        await pumpOnItel(
          tester,
          Column(
            children: [
              hero(household: 'Boutique Tié-Tié'),
              hero(online: false),
            ],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });
}
