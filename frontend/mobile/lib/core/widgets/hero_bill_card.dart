import 'dart:async';

import 'package:flutter/material.dart';

import '../format/dates.dart';
import '../format/numbers.dart';
import '../format/typography.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'app_button.dart';
import 'pay_button.dart';
import 'status_badge.dart';
import 'statuses.dart';

/// Carte de la facture la plus urgente, sur l'accueil (maquette de l'écran 5,
/// `frontend/design/components/HeroBillCard`). OPAQUE (`surface-1`) : le verre est réservé à la
/// barre du bas et aux feuilles (décision du 17/11/2026).
///
/// Ordre de lecture : période → montant → échéance (compte à rebours en `warning` à 5 jours, en
/// `error` après) → compteur et consommation → Détail / Payer.
class HeroBillCard extends StatelessWidget {
  const HeroBillCard({
    required this.periodLabel,
    required this.status,
    required this.amount,
    required this.dueDate,
    required this.now,
    required this.meterLabel,
    required this.consumptionKwh,
    required this.online,
    required this.onDetail,
    required this.onPay,
    this.householdName,
    this.payment = HeroPayment.pay,
    this.onOpenPayment,
    super.key,
  });

  /// Ce que propose la carte à côté de « Détail ».
  final HeroPayment payment;

  /// « Paiement en cours » touché : ouvre le suivi du paiement (jamais une nouvelle demande).
  final VoidCallback? onOpenPayment;

  /// « sept.–oct. 2026 » (format court de la période).
  final String periodLabel;
  final StatusStyle status;
  final int amount;
  final DateTime dueDate;
  final DateTime now;

  /// « 0412-8833 ».
  final String meterLabel;
  final num consumptionKwh;
  final bool online;
  final VoidCallback onDetail;
  final FutureOr<void> Function() onPay;

  /// Plusieurs foyers : le nom du foyer de la facture (« Maison Mpita »).
  final String? householdName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final countdown = dueCountdown(dueDate, now: now);
    final countdownColor = switch (countdown.urgency) {
      DueUrgency.normal => c.inkMuted,
      DueUrgency.soon => c.warningText,
      DueUrgency.overdue => c.errorText,
    };
    final overline = ['Facture de $periodLabel', ?householdName].join(' · ');

    return Container(
      padding: const EdgeInsets.all(Space.s5),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.xl)),
        boxShadow: context.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              Text(overline.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
              StatusBadge(status),
            ],
          ),
          const SizedBox(height: Space.s4),
          Semantics(
            label: formatFcfa(amount),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatFcfaValue(amount),
                    style: AppText.amountHero.copyWith(color: c.ink, fontSize: 40, height: 1.1),
                  ),
                  TextSpan(
                    text: '${unitSpace}FCFA',
                    style: AppText.body.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Échéance le ${formatCalendarDate(dueDate)} · '),
                TextSpan(
                  text: countdown.text,
                  style: TextStyle(
                    color: countdownColor,
                    fontWeight: countdown.urgency == DueUrgency.normal ? null : FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppText.bodySm.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.s4),
          Wrap(
            spacing: Space.s4,
            runSpacing: Space.s2,
            children: [
              _Meta(icon: AppIcons.meter, text: 'Compteur $meterLabel'),
              _Meta(icon: AppIcons.energy, text: formatKwh(consumptionKwh)),
            ],
          ),
          const SizedBox(height: Space.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (payment == HeroPayment.none)
                Expanded(
                  child: AppButton(
                    label: 'Détail',
                    variant: ButtonVariant.secondary,
                    onPressed: onDetail,
                  ),
                )
              else ...[
                AppButton(label: 'Détail', variant: ButtonVariant.secondary, onPressed: onDetail),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: payment == HeroPayment.inProgress
                      ? AppButton(
                          label: 'Paiement en cours',
                          icon: AppIcons.hourglass,
                          variant: ButtonVariant.secondary,
                          onPressed: onOpenPayment,
                        )
                      : PayButton(amount: amount, online: online, onPay: onPay),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Action de paiement de la carte de la facture urgente.
enum HeroPayment {
  /// « Payer 31 420 FCFA » (désactivé hors ligne).
  pay,

  /// « Paiement en cours » : un paiement attend sa confirmation, on n'en lance pas un deuxième.
  inProgress,

  /// Pas de paiement possible ici (ex. simple lecteur du foyer) : « Détail » seul.
  none,
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 16, color: c.inkMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: AppText.bodySm.copyWith(color: c.inkMuted)),
        ),
      ],
    );
  }
}

/// Aucune facture à payer : « Tout est payé » en `success` et la date de la prochaine facture.
class AllPaidCard extends StatelessWidget {
  const AllPaidCard({this.nextBillDate, super.key});

  /// Date prévue de la prochaine facture (date du calendrier), si elle est connue.
  final DateTime? nextBillDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.s5),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.xl)),
        boxShadow: context.shadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
            child: AppIcon(AppIcons.check, size: 24, color: c.success),
          ),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tout est payé', style: AppText.h2.copyWith(color: c.successText)),
                if (nextBillDate != null)
                  Text(
                    'Prochaine facture prévue le ${formatCalendarDate(nextBillDate!)}',
                    style: AppText.bodySm.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
