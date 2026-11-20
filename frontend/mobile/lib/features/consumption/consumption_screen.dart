import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/cache/cached_api.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/consumption.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../home/home_screen.dart' show homeClockProvider;
import 'consumption_chart.dart';
import 'consumption_data.dart';
import 'consumption_day.dart';
import 'consumption_direct.dart';
import 'consumption_rules.dart';

/// Écran 11 : Consommation (maquette `Consommation.dc.html`). Onglets Direct · Jour · Semaine ·
/// Mois · Année (Mois par défaut), fil d'Ariane, flèches ‹ ›, sélecteur de compteur.
/// Relevés journaliers ou estimés : jamais « temps réel ».
class ConsumptionScreen extends ConsumerStatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  ConsumerState<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends ConsumerState<ConsumptionScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Nouvelle période (barre, ligne, onglet, fil d'Ariane) : elle se lit depuis le haut.
  void _backToTop() {
    if (!_scroll.hasClients || _scroll.offset == 0) return;
    final duration = Motion.of(context, Motion.appear);
    if (duration == Duration.zero) {
      _scroll.jumpTo(0);
    } else {
      unawaited(_scroll.animateTo(0, duration: duration, curve: Motion.curve));
    }
  }

  Future<void> _refresh(WidgetRef ref, SeriesKey? key) async {
    ref.invalidate(allMetersProvider);
    if (key == null) return;
    ref.invalidate(consumptionSeriesProvider(key));
    try {
      await ref.read(consumptionSeriesProvider(key).future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.listen(consumptionCursorProvider, (_, _) => _backToTop());
    final cursor = ref.watch(consumptionCursorProvider);
    final meterId = ref.watch(consumptionMeterIdProvider);
    final meters = ref.watch(allMetersProvider);
    final id = meterId.value;
    final key = id == null || cursor.level == ConsumptionLevel.direct
        ? null
        : seriesKey(id, cursor.chartRange);
    final series = key == null ? null : ref.watch(consumptionSeriesProvider(key));
    final today = toBrazzaville(ref.watch(homeClockProvider)());
    final choice = meters.value?.where((m) => m.meter.id == id).firstOrNull;
    void retry() {
      ref.invalidate(consumptionMeterIdProvider);
      unawaited(_refresh(ref, key));
    }

    final children = <Widget>[
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s3,
        runSpacing: Space.s2,
        children: [
          Semantics(
            header: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Consommation', style: AppText.h1.copyWith(color: c.ink)),
            ),
          ),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ref.watch(demoModeProvider).showBadge) const DemoBadge(),
              if (meters.value case final list? when choice != null)
                _MeterSelector(
                  label: meterChoiceLabel(choice, list),
                  onTap: list.length > 1
                      ? () => unawaited(_chooseMeter(context, ref, list, choice.meter.id))
                      : null,
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: Space.s3),
      _LevelTabs(
        selected: cursor.level,
        onSelect: (l) => ref
            .read(consumptionCursorProvider.notifier)
            .level(l, lastReading: series?.value?.data.measuredUntil),
      ),
      if (series?.value case final CachedData<ConsumptionSeries> cached) ...[
        const SizedBox(height: Space.s3),
        OfflineBanner(cached.label),
      ],
      ...switch (meterId) {
        AsyncValue(hasValue: true, value: null) => [
          const SizedBox(height: Space.s6),
          StateBlock.empty(
            key: const Key('conso.noMeter'),
            icon: AppIcons.meter,
            title: 'Aucun compteur',
            message: 'Ajoutez votre compteur E²C pour suivre votre consommation.',
            actionLabel: 'Ajouter un compteur',
            onAction: () => unawaited(context.push(Routes.pending('Compteurs & foyers', 'F8'))),
          ),
        ],
        AsyncError(:final error) => [const SizedBox(height: Space.s6), _failure(error, retry)],
        _ when cursor.level == ConsumptionLevel.direct => [
          const SizedBox(height: Space.s4),
          if (id != null)
            _DirectTab(meterId: id, subscribedPowerVa: choice?.meter.subscribedPowerVa),
        ],
        _ => [
          const SizedBox(height: Space.s2),
          _Breadcrumb(
            cursor: cursor,
            onSelect: (target) => ref.read(consumptionCursorProvider.notifier).show(target),
          ),
          const SizedBox(height: Space.s1),
          _PeriodArrows(
            title: cursor.title,
            onPrevious: cursor.canGoPrevious(choice?.meter.installedAt)
                ? () => ref.read(consumptionCursorProvider.notifier).show(cursor.previous)
                : null,
            onNext: cursor.canGoNext(today)
                ? () => ref.read(consumptionCursorProvider.notifier).show(cursor.next)
                : null,
          ),
          const SizedBox(height: Space.s3),
          ...switch (series) {
            AsyncValue(:final value?) => [
              _PeriodBody(cursor: cursor, series: value.data, meterId: id!),
            ],
            AsyncError(:final error) => [const SizedBox(height: Space.s4), _failure(error, retry)],
            _ => [
              const AppSkeleton(
                loading: true,
                child: _TotalsBlock(
                  totals: (
                    label: 'Du 1er au 12 novembre',
                    wh: 82600,
                    daysWithData: 12,
                    energyCost: 4054,
                    comparison: '+6 % vs 2025',
                    trend: Trend.up,
                  ),
                ),
              ),
            ],
          },
        ],
      },
    ];

    // Simulation de l'onglet Direct : seulement si /health a CONFIRMÉ le mode démo (D7.2).
    final simulating =
        cursor.level == ConsumptionLevel.direct && ref.watch(demoModeProvider).known == true;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixé hors de la liste : toujours visible, même en faisant défiler.
            if (simulating) const DirectDemoBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(ref, key),
                child: ListView(
                  key: const Key('conso.list'),
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(Space.s4, Space.s5, Space.s4, 120),
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseMeter(
    BuildContext context,
    WidgetRef ref,
    List<MeterChoice> meters,
    int shownId,
  ) async {
    final chosen = await showAppSheet<int>(
      context,
      child: _MeterChoiceList(meters: meters, shownId: shownId),
    );
    if (chosen != null) ref.read(chosenConsumptionMeterProvider.notifier).choose(chosen);
  }
}

/// Contenu d'une période une fois sa série lue : total, pastilles, graphique, liste, facture.
class _PeriodBody extends ConsumerWidget {
  const _PeriodBody({required this.cursor, required this.series, required this.meterId});

  final ConsumptionCursor cursor;
  final ConsumptionSeries series;
  final int meterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vue Jour : le calendrier du mois reste visible même si le jour n'est pas encore relevé.
    if (cursor.level == ConsumptionLevel.day && series.points.any((p) => p.daysWithData > 0)) {
      return _DayBody(cursor: cursor, series: series, meterId: meterId);
    }
    final totals = periodTotals(cursor, series);
    if (totals.daysWithData == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: Space.s4),
        child: StateBlock.empty(
          key: Key('conso.emptyPeriod'),
          icon: AppIcons.meter,
          title: 'Pas encore de relevé',
          message: 'Aucun relevé pour cette période. ElecPay reçoit un relevé par jour.',
        ),
      );
    }
    void open(ConsumptionCursor target) =>
        ref.read(consumptionCursorProvider.notifier).show(target);
    final a = cursor.anchor;
    final children = <Widget>[_TotalsBlock(totals: totals)];

    void addStats(List<PeriodStat> stats) {
      if (stats.isEmpty) return;
      children.addAll([const SizedBox(height: Space.s3), PeriodStats(stats: stats)]);
    }

    void addChart(ConsumptionBars chart) => children.addAll([const SizedBox(height: 14), chart]);

    void addList(String title, List<PeriodRow> rows) {
      if (rows.isEmpty) return;
      children.addAll([
        const SizedBox(height: Space.s4),
        PeriodList(title: title, rows: rows, onSelect: open),
      ]);
    }

    switch (cursor.level) {
      case ConsumptionLevel.year:
        addStats(yearStats(series));
        addChart(
          ConsumptionBars(
            bars: yearBars(series),
            label: 'Consommation par mois en ${a.year}',
            hint: 'Touchez un mois pour voir ses jours et ses semaines',
            onSelect: open,
          ),
        );
        addList('Mois par mois', yearRows(series));
      case ConsumptionLevel.month:
        // Estimation de fin de mois : seulement pour le mois en cours.
        final current = series.points.any((p) => p.isCurrent);
        final estimate = current
            ? ref.watch(consumptionSummaryProvider(meterId)).value?.data.monthEndEstimate
            : null;
        addStats(monthStats(series, estimate: estimate));
        addChart(
          ConsumptionBars(
            bars: monthBars(series),
            gap: 2,
            label: 'Consommation par jour en ${formatMonthYear(a.year, a.month).toLowerCase()}',
            hint: 'Touchez un jour pour son détail, ou une semaine ci-dessous',
            onSelect: open,
          ),
        );
        addList('Semaine par semaine', monthWeekRows(series));
        final bill = ref.watch(billForMonthProvider((meterId: meterId, month: a))).value;
        if (bill != null) {
          children.addAll([
            const SizedBox(height: Space.s3),
            BillLink(
              text:
                  'Voir la facture de ${formatBillPeriodLong(bill.periodStart, bill.periodEnd)} '
                  '(bimestrielle)',
              onTap: () => unawaited(context.push(Routes.bill(bill.id))),
            ),
          ]);
        }
      case ConsumptionLevel.week:
        addStats(monthStats(series));
        addChart(
          ConsumptionBars(
            bars: weekBars(series),
            label: 'Consommation par jour de la semaine',
            hint: 'Touchez un jour pour son détail',
            onSelect: open,
          ),
        );
        final readings = ref
            .watch(readingsProvider((meterId: meterId, from: a, to: cursor.end)))
            .value
            ?.data
            .items;
        addList('Jour par jour', weekDayRows(series, readings ?? const []));
      case ConsumptionLevel.day || ConsumptionLevel.direct:
        break;
    }
    children.addAll([
      const SizedBox(height: Space.s4),
      _ReadingLegend(measuredUntil: series.measuredUntil),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// Vue Jour : total du jour (comparé à la moyenne du même jour), calendrier du mois, carte du
/// jour. Jour pas encore relevé : un message à la place du total et de la carte.
class _DayBody extends ConsumerWidget {
  const _DayBody({required this.cursor, required this.series, required this.meterId});

  final ConsumptionCursor cursor;
  final ConsumptionSeries series;
  final int meterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = cursor.anchor;
    final detail = ref.watch(dayDetailProvider((meterId: meterId, day: day)));
    final reading = ref
        .watch(readingsProvider((meterId: meterId, from: day, to: day)))
        .value
        ?.data
        .items
        .firstOrNull;
    final calendar = DayCalendar(
      cells: calendarCells(series, day),
      onSelect: (d) => ref
          .read(consumptionCursorProvider.notifier)
          .show(ConsumptionCursor.of(ConsumptionLevel.day, d)),
    );
    final notRead = switch (detail) {
      AsyncError(:final error) => error is ApiRejected && error.statusCode == 404,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...switch (detail) {
          AsyncValue(:final value?) => [_TotalsBlock(totals: dayTotals(value.data))],
          _ when notRead => [
            const StateBlock.empty(
              key: Key('conso.dayNotRead'),
              icon: AppIcons.clock,
              title: 'Pas encore de relevé',
              message:
                  'Le relevé de ce jour arrive le lendemain matin. ElecPay reçoit un relevé '
                  'par jour.',
            ),
          ],
          AsyncError(:final error) => [
            _failure(error, () => ref.invalidate(dayDetailProvider((meterId: meterId, day: day)))),
          ],
          _ => [
            const AppSkeleton(
              loading: true,
              child: _TotalsBlock(
                totals: (
                  label: 'Consommation du jour',
                  wh: 9000,
                  daysWithData: 1,
                  energyCost: 441,
                  comparison: null,
                  trend: null,
                ),
              ),
            ),
          ],
        },
        const SizedBox(height: 14),
        calendar,
        if (detail.value?.data case final data?) ...[
          const SizedBox(height: Space.s3),
          DayDetailCard(card: dayCard(data, reading: reading)),
        ],
        const SizedBox(height: Space.s4),
        _ReadingLegend(measuredUntil: series.measuredUntil),
      ],
    );
  }
}

Widget _failure(Object error, VoidCallback retry) => error is ApiFailure
    ? stateForFailure(error, what: 'votre consommation', onRetry: retry)
    : StateBlock.error(what: 'votre consommation', onRetry: retry);

/// Nom du compteur dans le sélecteur : le foyer seul (maquette), ou « foyer · compteur » quand le
/// foyer a plusieurs compteurs.
String meterChoiceLabel(MeterChoice choice, List<MeterChoice> all) {
  final siblings = all.where((m) => m.household.id == choice.household.id).length;
  return siblings > 1 ? '${choice.household.name} · ${meterName(choice)}' : choice.household.name;
}

/// « Compteur cuisine », sinon « Compteur 0412-778 » (sa référence).
String meterName(MeterChoice choice) =>
    choice.meter.label ?? 'Compteur ${formatReference(choice.meter.reference)}';

/// Bouton « Maison Mpita ⌄ » en haut à droite. `onTap` `null` : un seul compteur (rien à choisir).
class _MeterSelector extends StatelessWidget {
  const _MeterSelector({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: onTap != null,
      label: onTap == null ? 'Compteur : $label' : 'Compteur : $label. Changer de compteur',
      excludeSemantics: true,
      child: Material(
        color: c.surface1,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          key: const Key('conso.meter'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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

/// Feuille « Choisir un compteur » : renvoie (pop) l'identifiant choisi.
class _MeterChoiceList extends StatelessWidget {
  const _MeterChoiceList({required this.meters, required this.shownId});

  final List<MeterChoice> meters;
  final int shownId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Choisir un compteur', style: AppText.h2.copyWith(color: c.ink)),
        ),
        const SizedBox(height: Space.s3),
        for (final m in meters)
          Semantics(
            selected: m.meter.id == shownId,
            button: true,
            child: InkWell(
              key: Key('conso.meter.${m.meter.id}'),
              borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              onTap: () => Navigator.of(context).pop(m.meter.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s2),
                  child: Row(
                    children: [
                      AppIcon(AppIcons.meter, color: c.inkMuted),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.household.name,
                              style: AppText.bodyStrong.copyWith(color: c.ink),
                            ),
                            Text(meterName(m), style: AppText.bodySm.copyWith(color: c.inkMuted)),
                          ],
                        ),
                      ),
                      if (m.meter.id == shownId) AppIcon(AppIcons.check, color: c.current),
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

/// Onglets « Niveau de détail » (contrôle segmenté de la maquette). Texte agrandi : les onglets
/// passent sur deux lignes plutôt que d'être tronqués ou cachés.
class _LevelTabs extends StatelessWidget {
  const _LevelTabs({required this.selected, required this.onSelect});

  final ConsumptionLevel selected;
  final ValueChanged<ConsumptionLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(ConsumptionLevel level, {required bool fill}) {
      final on = level == selected;
      return Semantics(
        selected: on,
        button: true,
        inMutuallyExclusiveGroup: true,
        label: level.label,
        excludeSemantics: true,
        child: Material(
          color: on ? c.surface1 : Colors.transparent,
          elevation: 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key('conso.tab.${level.name}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelect(level),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: EdgeInsets.symmetric(horizontal: fill ? 2 : Space.s3),
              decoration: on
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: context.shadows.card,
                    )
                  : null,
              // En colonnes : centré dans sa colonne ; à la ligne : largeur du libellé.
              child: Center(
                widthFactor: fill ? null : 1,
                heightFactor: 1,
                child: Text(
                  level.label,
                  maxLines: 1,
                  style: AppText.bodySm.copyWith(
                    color: on ? c.ink : c.inkMuted,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Niveau de détail',
      child: Container(
        padding: const EdgeInsets.all(Space.s1),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // Une ligne, chaque onglet à la mesure de son libellé (« Semaine » est deux fois plus
            // long que « Mois » : 5 colonnes égales ne tiennent pas sur les 360 points de l'itel).
            // Texte agrandi qui ne tient plus : les onglets passent à la ligne, tous visibles.
            final scaler = MediaQuery.textScalerOf(context);
            final style = AppText.bodySm.copyWith(fontWeight: FontWeight.w600);
            final widths = [
              for (final l in ConsumptionLevel.values)
                () {
                  final painter = TextPainter(
                    text: TextSpan(text: l.label, style: style),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout();
                  final width = painter.width + Space.s2 * 2;
                  painter.dispose();
                  return width;
                }(),
            ];
            final needed = widths.fold(0.0, (s, w) => s + w) + Space.s1 * (widths.length - 1);
            if (needed <= box.maxWidth) {
              return Row(
                children: [
                  for (final (i, l) in ConsumptionLevel.values.indexed) ...[
                    Expanded(flex: widths[i].round(), child: tab(l, fill: true)),
                    if (l != ConsumptionLevel.values.last) const SizedBox(width: Space.s1),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: Space.s1,
              runSpacing: Space.s1,
              children: [for (final l in ConsumptionLevel.values) tab(l, fill: false)],
            );
          },
        ),
      ),
    );
  }
}

/// Fil d'Ariane : « 2026 › Octobre › Sem. du 12 oct. › Mer. 14 » ; chaque élément (sauf le
/// dernier) ramène à son niveau.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.cursor, required this.onSelect});

  final ConsumptionCursor cursor;
  final ValueChanged<ConsumptionCursor> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final crumbs = cursor.breadcrumb;
    return Semantics(
      container: true,
      label: "Fil d'Ariane",
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text('›', style: AppText.bodySm.copyWith(color: c.inkFaint)),
                ),
              ),
            if (i == crumbs.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s1, vertical: 12),
                child: Text(
                  crumb.label,
                  style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                ),
              )
            else
              Semantics(
                button: true,
                label: 'Voir ${crumb.label}',
                excludeSemantics: true,
                child: InkWell(
                  key: Key('conso.crumb.${crumb.cursor.level.name}'),
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
                  onTap: () => onSelect(crumb.cursor),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.s1),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          crumb.label,
                          style: AppText.bodySm.copyWith(
                            color: c.voltText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// « ‹  Octobre 2026  › » : flèches rondes de 44, grisées au bout (pas de futur, pas avant la pose
/// du compteur).
class _PeriodArrows extends StatelessWidget {
  const _PeriodArrows({required this.title, required this.onPrevious, required this.onNext});

  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget arrow(IconData icon, String label, VoidCallback? onTap, String key) => Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Material(
          color: c.surface1,
          shape: CircleBorder(side: BorderSide(color: c.line)),
          child: InkWell(
            key: Key(key),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Center(child: AppIcon(icon, color: onTap == null ? c.inkFaint : c.ink)),
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        arrow(AppIcons.previous, 'Période précédente', onPrevious, 'conso.previous'),
        const SizedBox(width: Space.s2),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              title,
              key: const Key('conso.period'),
              textAlign: TextAlign.center,
              style: AppText.bodyStrong.copyWith(color: c.ink, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: Space.s2),
        arrow(AppIcons.next, 'Période suivante', onNext, 'conso.next'),
      ],
    );
  }
}

/// Total de la période : « DU 1ER AU 12 NOVEMBRE », « 82,6 kWh », « ≈ 4 054 FCFA d'énergie »,
/// pastille de comparaison (hausse : orange ; baisse : vert).
class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.totals});

  final PeriodTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cost = totals.energyCost;
    final up = totals.trend == Trend.up;
    final spoken = [
      '${totals.label} : ${formatKwh(totals.wh / 1000)}',
      if (cost != null) "environ ${formatFcfa(cost)} d'énergie",
      ?totals.comparison,
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Wrap(
        key: const Key('conso.totals'),
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Space.s3,
        runSpacing: Space.s2,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(totals.label.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatKwhValue(totals.wh / 1000),
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
              if (cost != null)
                Text(
                  "${formatAboutFcfa(cost)} d'énergie",
                  style: AppText.bodySm.copyWith(color: c.inkMuted),
                ),
            ],
          ),
          if (totals.comparison case final text?)
            Container(
              key: const Key('conso.delta'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Space.s1),
              decoration: BoxDecoration(
                color: up ? c.warningSoft : c.successSoft,
                borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
              ),
              child: Text(
                text,
                style: AppText.caption.copyWith(
                  color: up ? c.warningText : c.successText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Légende du bas : « ■ Relevé  ▢ Estimation  Un relevé par jour · dernier : 11 nov. ».
class _ReadingLegend extends StatelessWidget {
  const _ReadingLegend({required this.measuredUntil});

  final DateTime? measuredUntil;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppText.caption.copyWith(color: c.inkFaint);
    Widget swatch({required Color fill, Color? border}) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
    );
    return Wrap(
      key: const Key('conso.legend'),
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(fill: c.current),
            const SizedBox(width: 6),
            Text('Relevé', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch(fill: c.warningSoft, border: c.warning),
            const SizedBox(width: 6),
            Text('Estimation', style: style),
          ],
        ),
        Text(
          [
            'Un relevé par jour',
            if (measuredUntil case final day?) 'dernier : ${formatDayMonth(day)}',
          ].join(' · '),
          style: style,
        ),
      ],
    );
  }
}

/// Onglet Direct : simulation en mode démo confirmé, sinon « phase 2 ».
class _DirectTab extends ConsumerWidget {
  const _DirectTab({required this.meterId, required this.subscribedPowerVa});

  final int meterId;
  final int? subscribedPowerVa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(demoModeProvider).known != true) return const _DirectUnavailable();
    final summary = ref.watch(consumptionSummaryProvider(meterId));
    return switch (summary) {
      AsyncValue(:final value?) => DirectSimulation(
        key: ValueKey('conso.direct.$meterId'),
        summary: value.data,
        subscribedPowerVa: subscribedPowerVa,
        now: toBrazzaville(ref.read(homeClockProvider)()),
        random: ref.read(directRandomProvider),
      ),
      AsyncError(:final error) => _failure(
        error,
        () => ref.invalidate(consumptionSummaryProvider(meterId)),
      ),
      _ => const Center(
        child: Padding(padding: EdgeInsets.all(Space.s6), child: CircularProgressIndicator()),
      ),
    };
  }
}

/// Onglet Direct sans simulation : la puissance instantanée demande un compteur communicant.
class _DirectUnavailable extends StatelessWidget {
  const _DirectUnavailable();

  @override
  Widget build(BuildContext context) => const StateBlock.empty(
    key: Key('conso.directUnavailable'),
    icon: AppIcons.energy,
    title: 'Disponible avec un compteur communicant (phase 2)',
    message:
        'Avec un compteur classique, ElecPay reçoit un relevé par jour. Consultez les onglets '
        'Jour, Semaine, Mois et Année.',
  );
}
