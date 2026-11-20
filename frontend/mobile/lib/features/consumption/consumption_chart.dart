import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format/formats.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.g.dart';
import 'consumption_rules.dart';

// Graphiques et listes de l'écran 11 (maquette `Consommation.dc.html`).

/// Hauteur de la zone des barres (maquette : 150).
const chartHeight = 150.0;

/// Barres fl_chart (relevé : bleu plein ; estimation : pointillé orange ; sans relevé : trait gris).
/// fl_chart ne sait pas annoncer ses barres : une couche de zones tactiles, une par barre, porte le
/// toucher et ce que lit TalkBack (« 14 octobre : 9 kWh »).
class ConsumptionBars extends StatelessWidget {
  const ConsumptionBars({
    required this.bars,
    required this.label,
    required this.hint,
    required this.onSelect,
    this.gap = 6,
    super.key,
  });

  final List<ChartBar> bars;

  /// Nom du graphique pour TalkBack : « Consommation par jour en novembre 2026 ».
  final String label;

  /// Phrase sous le graphique : « Touchez un jour pour son détail… ».
  final String hint;
  final ValueChanged<ConsumptionCursor> onSelect;

  /// Écart entre deux barres (maquette : 2 pour le mois, 6 ailleurs).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxWh = bars.fold(0, (m, b) => b.hasData && b.wh > m ? b.wh : m);
    final top = maxWh == 0 ? 1.0 : maxWh / 1000;
    final showValues = bars.any((b) => b.value != null);
    // Place au-dessus des barres pour leur valeur (vue Semaine).
    final maxY = top * (showValues ? 1.3 : 1.0);
    final axisStyle = AppText.caption.copyWith(
      color: c.inkMuted,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.s3, 14, Space.s3, 10),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: label,
            explicitChildNodes: true,
            child: SizedBox(
              height: chartHeight,
              child: LayoutBuilder(
                builder: (context, box) {
                  final slot = box.maxWidth / bars.length;
                  final width = (slot - gap).clamp(2.0, 28.0);
                  final radius = (width / 2).clamp(1.0, 5.0);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: BarChart(
                            key: const Key('conso.chart'),
                            duration: Motion.of(context, Motion.appear),
                            curve: Motion.curve,
                            BarChartData(
                              minY: 0,
                              maxY: maxY,
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: const BarTouchData(enabled: false),
                              titlesData: const FlTitlesData(show: false),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(bottom: BorderSide(color: c.line)),
                              ),
                              barGroups: [
                                for (final (i, b) in bars.indexed)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        // Sans relevé : un trait de 3 points.
                                        toY: b.hasData ? b.wh / 1000 : maxY * 3 / chartHeight,
                                        width: width,
                                        color: !b.hasData
                                            ? c.surface3
                                            : b.estimated
                                            ? c.warningSoft
                                            : c.current,
                                        borderSide: b.hasData && b.estimated
                                            ? BorderSide(color: c.warning, width: 1.5)
                                            : null,
                                        borderDashArray: b.hasData && b.estimated
                                            ? const [4, 3]
                                            : null,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(radius),
                                          bottom: const Radius.circular(1),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, b) in bars.indexed)
                            Expanded(
                              child: Semantics(
                                button: b.target != null,
                                label: b.spoken,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  key: Key('conso.bar.$i'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: b.target == null ? null : () => onSelect(b.target!),
                                  child: b.value == null
                                      ? const SizedBox.expand()
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              b.value!,
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              style: axisStyle.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  (b.hasData ? b.wh / 1000 / maxY : 0) *
                                                      chartHeight +
                                                  4,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final b in bars)
                  Expanded(
                    child: Text(
                      b.axis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: axisStyle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: c.inkFaint),
          ),
        ],
      ),
    );
  }
}

/// Pastilles sous le total : « Moyenne 6,9 kWh/jour », « Pic Mer. 14 · 9,4 kWh »,
/// « Fin de mois estimée ≈ 248 kWh · ≈ 12 200 FCFA » (fond orange pâle).
class PeriodStats extends StatelessWidget {
  const PeriodStats({required this.stats, super.key});

  final List<PeriodStat> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in stats)
          Semantics(
            container: true,
            label: '${s.label} : ${s.value}',
            excludeSemantics: true,
            child: Container(
              key: Key('conso.stat.${s.label}'),
              constraints: const BoxConstraints(minHeight: 30),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Space.s1),
              decoration: BoxDecoration(
                color: s.estimate ? c.warningSoft : c.surface1,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${s.label} ',
                      style: TextStyle(color: c.inkMuted),
                    ),
                    TextSpan(text: s.value),
                  ],
                ),
                style: AppText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// Liste « Mois par mois », « Semaine par semaine » ou « Jour par jour » : titre, sous-titre,
/// « Estimé », jauge relative, valeur, chevron. Toucher : la période.
class PeriodList extends StatelessWidget {
  const PeriodList({required this.title, required this.rows, required this.onSelect, super.key});

  final String title;
  final List<PeriodRow> rows;
  final ValueChanged<ConsumptionCursor> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxWh = rows.fold(1, (m, r) => r.wh > m ? r.wh : m);
    // Texte très agrandi : la jauge laisse sa place au texte.
    final gauge = MediaQuery.textScalerOf(context).scale(14) <= 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(height: Space.s2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (final (i, r) in rows.indexed)
                  Semantics(
                    button: true,
                    label: [
                      r.title,
                      formatKwh(r.wh / 1000),
                      r.subtitle,
                      if (r.estimated) 'estimé',
                    ].join(', '),
                    excludeSemantics: true,
                    child: InkWell(
                      key: Key('conso.row.$i'),
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? const Radius.circular(Radii.lg) : Radius.zero,
                        bottom: i == rows.length - 1
                            ? const Radius.circular(Radii.lg)
                            : Radius.zero,
                      ),
                      onTap: () => onSelect(r.target),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s3, Space.s2),
                        decoration: i == 0
                            ? null
                            : BoxDecoration(
                                border: Border(top: BorderSide(color: c.line)),
                              ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: AppText.bodySm.copyWith(
                                      color: c.ink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    r.subtitle,
                                    style: AppText.caption.copyWith(color: c.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (r.estimated) ...[
                              const SizedBox(width: Space.s2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.warningSoft,
                                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                                ),
                                child: Text(
                                  'Estimé',
                                  style: AppText.caption.copyWith(
                                    color: c.warningText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (gauge) ...[
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  width: 64,
                                  height: 6,
                                  child: ColoredBox(
                                    color: c.surface3,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: r.wh / maxWh,
                                      child: ColoredBox(color: c.current),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 56),
                              child: Text(
                                formatKwhValue(r.wh / 1000),
                                textAlign: TextAlign.right,
                                style: AppText.bodySm.copyWith(
                                  color: c.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.s1),
                            AppIcon(AppIcons.next, size: 14, color: c.inkFaint),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Lien « Voir la facture de septembre–octobre 2026 (bimestrielle) ».
class BillLink extends StatelessWidget {
  const BillLink({required this.text, required this.onTap, super.key});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
        child: InkWell(
          key: const Key('conso.bill'),
          borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Center(child: AppIcon(AppIcons.bill, size: 18, color: c.inkMuted)),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Text(
                    text,
                    style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                  ),
                ),
                AppIcon(AppIcons.next, size: 14, color: c.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
