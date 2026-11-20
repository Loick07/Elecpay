import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format/formats.dart';
import '../../core/models/households.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/demo_badge.dart';
import 'home_rules.dart';

// Morceaux de l'écran Accueil (maquette `Main.dc.html`). Ils ne reçoivent que des valeurs simples :
// les squelettes de chargement les affichent avec des valeurs d'exemple.

/// En-tête : date du jour, « Bonjour Loick », badge Mode démo, cloche avec un point rouge.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.date,
    required this.firstName,
    required this.unread,
    required this.showDemoBadge,
    required this.onNotifications,
    super.key,
  });

  /// « Jeudi 12 novembre ».
  final String date;

  /// `null` : compte pas encore lu (ou illisible) → « Bonjour ».
  final String? firstName;

  /// Notifications non lues (`null` : inconnu → pas de point).
  final int? unread;
  final bool showDemoBadge;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = unread ?? 0;
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date, style: AppText.bodySm.copyWith(color: c.inkMuted)),
        Semantics(
          header: true,
          child: Text(
            firstName == null ? 'Bonjour' : 'Bonjour $firstName',
            style: AppText.h1.copyWith(color: c.ink),
          ),
        ),
      ],
    );
    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        if (showDemoBadge) const DemoBadge(),
        Semantics(
          container: true, // un élément à part pour TalkBack (pas fusionné avec la date)
          button: true,
          label: count > 0
              ? 'Notifications, $count non lue${count > 1 ? 's' : ''}'
              : 'Notifications',
          excludeSemantics: true,
          child: Material(
            color: c.surface1,
            shape: CircleBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              key: const Key('home.bell'),
              customBorder: const CircleBorder(),
              onTap: onNotifications,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AppIcon(AppIcons.notifications, color: c.ink),
                    if (count > 0)
                      Positioned(
                        key: const Key('home.bell.dot'),
                        top: 11,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    // Texte très agrandi (vu sur l'itel à 200 % : « Vendr / edi », « Bon / jour ») : le badge et la
    // cloche passent AU-DESSUS, la date et le salut prennent toute la largeur.
    if (MediaQuery.textScalerOf(context).scale(10) > 14) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerRight, child: actions),
          const SizedBox(height: Space.s2),
          texts,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: texts),
        const SizedBox(width: Space.s3),
        actions,
      ],
    );
  }
}

/// Sélecteur de foyer : « Maison Mpita · 2 foyers ». Un seul foyer : son nom, sans menu.
class HouseholdSelector extends StatelessWidget {
  const HouseholdSelector({
    required this.households,
    required this.shownId,
    required this.onTap,
    super.key,
  });

  final List<HouseholdSummary> households;
  final int? shownId;

  /// `null` : un seul foyer (rien à choisir).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = households.where((h) => h.id == shownId).firstOrNull ?? households.first;
    final label = households.length > 1
        ? '${shown.name} · ${households.length} foyers'
        : shown.name;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: c.surface1,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          key: const Key('home.household'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.household, size: 16, color: c.ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    AppIcon(AppIcons.dropdown, size: 14, color: c.ink),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenu de la feuille « Choisir un foyer ». Renvoie (pop) l'identifiant choisi.
class HouseholdChoiceList extends StatelessWidget {
  const HouseholdChoiceList({required this.households, required this.shownId, super.key});

  final List<HouseholdSummary> households;
  final int? shownId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Choisir un foyer', style: AppText.h2.copyWith(color: c.ink)),
        ),
        const SizedBox(height: Space.s3),
        for (final h in households)
          Semantics(
            selected: h.id == shownId,
            child: InkWell(
              key: Key('home.household.${h.id}'),
              borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              onTap: () => Navigator.of(context).pop(h.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s2),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.household, color: c.inkMuted),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.name, style: AppText.bodyStrong.copyWith(color: c.ink)),
                            Text(
                              [h.city, ?h.district].join(' · '),
                              style: AppText.bodySm.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      if (h.id == shownId) AppIcon(AppIcons.check, color: c.current),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rappel sous la carte urgente : « 1 facture en retard dans Boutique Tié-Tié » (toucher : ce foyer).
class OverdueElsewhereRow extends StatelessWidget {
  const OverdueElsewhereRow({required this.overdue, required this.onTap, super.key});

  final OverdueElsewhere overdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.errorSoft,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      child: InkWell(
        key: Key('home.elsewhere.${overdue.householdId}'),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
            child: Row(
              children: [
                AppIcon(AppIcons.alert, size: 18, color: c.error),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Text(
                    overdueElsewhereText(overdue),
                    style: AppText.bodySm.copyWith(color: c.errorText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une barre des 12 derniers jours.
typedef DayBar = ({double kwh, bool dashed});

/// Carte du mois en cours : kWh depuis le 1er, estimation de fin de mois, barres des 12 derniers
/// jours (la dernière, journée pas finie, et les jours estimés en pointillé). Toucher : Conso.
class MonthCard extends StatelessWidget {
  const MonthCard({
    required this.overline,
    required this.kwh,
    required this.estimate,
    required this.bars,
    required this.onTap,
    super.key,
  });

  /// « Novembre, du 1er au 12 » (+ le nom du compteur s'il y en a plusieurs).
  final String overline;
  final num kwh;

  /// « Estimation fin de mois : ≈ 206 kWh · ≈ 10 100 FCFA » (`null` : pas d'estimation).
  final String? estimate;
  final List<DayBar> bars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface1,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      child: InkWell(
        key: const Key('home.month'),
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overline.toUpperCase(),
                      style: AppText.overline.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: Space.s1),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatKwhValue(kwh),
                            style: AppText.amount.copyWith(color: c.ink),
                          ),
                          TextSpan(
                            text: '${unitSpace}kWh',
                            style: AppText.bodySm.copyWith(
                              color: c.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (estimate != null) ...[
                      const SizedBox(height: Space.s1),
                      Text(estimate!, style: AppText.caption.copyWith(color: c.inkMuted)),
                    ],
                  ],
                ),
              ),
              if (bars.isNotEmpty) ...[const SizedBox(width: Space.s3), DayBars(bars)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Petites barres des derniers jours (104 × 56, maquette).
class DayBars extends StatelessWidget {
  const DayBars(this.bars, {super.key});

  final List<DayBar> bars;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Consommation des ${bars.length} derniers jours',
      excludeSemantics: true,
      child: CustomPaint(
        size: const Size(104, 56),
        painter: _DayBarsPainter(
          bars: bars,
          fill: c.current,
          dashedFill: c.warningSoft,
          dashedStroke: c.warning,
        ),
      ),
    );
  }
}

class _DayBarsPainter extends CustomPainter {
  _DayBarsPainter({
    required this.bars,
    required this.fill,
    required this.dashedFill,
    required this.dashedStroke,
  });

  final List<DayBar> bars;
  final Color fill;
  final Color dashedFill;
  final Color dashedStroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const gap = 3.0;
    final width = (size.width - gap * (bars.length - 1)) / bars.length;
    final highest = bars.map((b) => b.kwh).fold<double>(0, math.max);
    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final ratio = highest <= 0 ? 0.0 : bar.kwh / highest;
      final height = math.max(4, size.height * ratio).toDouble();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * (width + gap), size.height - height, width, height),
        Radius.circular(width / 2),
      );
      if (!bar.dashed) {
        canvas.drawRRect(rect, Paint()..color = fill);
        continue;
      }
      canvas.drawRRect(rect, Paint()..color = dashedFill);
      final stroke = Paint()
        ..color = dashedStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final metric in (Path()..addRRect(rect.deflate(0.5))).computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 5) {
          canvas.drawPath(metric.extractPath(d, math.min(d + 3, metric.length)), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DayBarsPainter old) =>
      old.bars != bars ||
      old.fill != fill ||
      old.dashedFill != dashedFill ||
      old.dashedStroke != dashedStroke;
}

/// Une ligne d'« Activité récente ».
typedef ActivityLine = ({bool payment, String title, String subtitle, int amount});

/// « Activité récente » avec « Tout voir », puis les lignes (paiements réussis, factures émises).
class ActivityCard extends StatelessWidget {
  const ActivityCard({required this.lines, required this.onSeeAll, super.key});

  final List<ActivityLine> lines;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Activité récente', style: AppText.h2.copyWith(color: c.ink)),
              ),
            ),
            TextButton(
              key: const Key('home.activity.all'),
              onPressed: onSeeAll,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                'Tout voir',
                style: AppText.bodySm.copyWith(color: c.voltText, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          ),
          child: lines.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Space.s4),
                  child: Text(
                    'Aucune activité pour l’instant.',
                    style: AppText.bodySm.copyWith(color: c.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                        ),
                        child: _ActivityRow(lines[i]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.line);

  final ActivityLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Texte très agrandi : le montant passe sous le titre (sinon il écrase le titre ou déborde).
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amount = Text(formatFcfa(line.amount), style: AppText.bodyStrong.copyWith(color: c.ink));
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: line.payment ? c.successSoft : c.surface2,
                borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              ),
              child: AppIcon(
                line.payment ? AppIcons.check : AppIcons.bill,
                color: line.payment ? c.success : c.inkMuted,
              ),
            ),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.title,
                    style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                  ),
                  Text(line.subtitle, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                  if (stacked) amount,
                ],
              ),
            ),
            if (!stacked) ...[const SizedBox(width: Space.s2), amount],
          ],
        ),
      ),
    );
  }
}

/// Lignes d'activité affichées (textes de la maquette).
/// La période d'un paiement est construite à partir de SES dates (`bill_period_start` /
/// `bill_period_end`) avec `formats.dart`, jamais reprise de `bill_period_label`.
List<ActivityLine> activityLines(List<ActivityItem> items) => [
  for (final item in items)
    switch (item) {
      PaymentActivity(:final payment) => (
        payment: true,
        title:
            'Facture de ${formatBillPeriodShort(payment.billPeriodStart, payment.billPeriodEnd)} '
            'payée',
        subtitle: [
          payment.operatorLabel,
          if (!payment.isMine) 'par ${payment.payerName}',
          formatDayMonth(toBrazzaville(item.at)),
        ].join(' · '),
        amount: item.amount,
      ),
      BillIssuedActivity(:final bill) => (
        payment: false,
        title: 'Nouvelle facture de ${formatBillPeriodShort(bill.periodStart, bill.periodEnd)}',
        subtitle: '${bill.householdName} · ${formatDayMonth(toBrazzaville(item.at))}',
        amount: item.amount,
      ),
    },
];

/// Une carte qui n'a pas pu se charger (les autres restent affichées) : ce qui manque,
/// « Réessayer », et la référence de la requête.
class CardFailure extends StatelessWidget {
  const CardFailure({required this.error, required this.what, required this.onRetry, super.key});

  final Object error;

  /// « votre facture », avec son article.
  final String what;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final failure = error is ApiFailure ? error as ApiFailure : null;
    // Session expirée : la feuille « session expirée » masque déjà tout l'écran.
    if (failure is SessionExpired) return const SizedBox.shrink();
    final message = failure is NoConnection
        ? 'Hors connexion : impossible de charger $what.'
        : 'Impossible de charger $what.';
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s2, Space.s3),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Row(
        children: [
          AppIcon(failure is NoConnection ? AppIcons.offline : AppIcons.error, color: c.error),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AppText.bodySm.copyWith(color: c.ink)),
                if (failure?.reference case final reference?)
                  Text(
                    'Référence : $reference',
                    style: AppText.caption.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('Réessayer', style: AppText.bodySm.copyWith(color: c.currentText)),
          ),
        ],
      ),
    );
  }
}
