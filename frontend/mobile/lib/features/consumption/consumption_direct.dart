import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format/formats.dart';
import '../../core/models/consumption.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.g.dart';

// Onglet Direct de l'écran 11 (D7.2). L'API n'a AUCUNE route de puissance instantanée (phase 2 :
// compteur communicant ou capteur). En mode démo seulement, l'application SIMULE une puissance
// autour de la moyenne réelle du compteur, toutes les 2 s, avec le bandeau « Mode démo ·
// simulation » toujours visible. Rien n'est envoyé ni enregistré. Jamais « temps réel ».

/// Intervalle entre deux valeurs simulées.
const directInterval = Duration(seconds: 2);

/// Nombre de valeurs gardées pour la courbe (40 × 2 s = 80 s).
const directHistory = 40;

/// Simulation de la puissance appelée (kW), en mémoire seulement.
class DirectSimulator {
  DirectSimulator({required this.averageKw, required this.todayKwh, Random? random})
    : _random = random ?? Random() {
    var kw = averageKw;
    for (var i = 0; i < directHistory; i++) {
      kw = _step(kw);
      history.add(kw);
    }
  }

  /// Puissance moyenne du compteur (consommation moyenne d'un jour ÷ 24 h).
  final double averageKw;
  final Random _random;

  /// Les 40 dernières valeurs, de la plus ancienne à la plus récente.
  final List<double> history = [];

  /// Énergie depuis minuit (estimation de départ + valeurs simulées).
  double todayKwh;

  double get current => history.last;

  /// Une marche au hasard autour de la moyenne, avec des appels de puissance (fer, climatiseur)
  /// qui retombent : jamais sous 30 % ni au-dessus de 3 fois la moyenne.
  double _step(double kw) {
    var next = kw + (_random.nextDouble() - 0.5) * 0.35 * averageKw;
    if (_random.nextDouble() < 0.06) next += 1.1 * averageKw;
    if (next > 2.4 * averageKw && _random.nextDouble() < 0.3) next -= averageKw;
    return next.clamp(0.3 * averageKw, 3 * averageKw);
  }

  /// Valeur suivante (toutes les 2 s).
  void tick() {
    final kw = _step(current);
    history
      ..removeAt(0)
      ..add(kw);
    todayKwh += kw * directInterval.inSeconds / 3600;
  }
}

/// Niveau d'une puissance (maquette) : sous 0,8 kW faible, sous 2 kW normale, sinon élevée.
enum PowerLevel {
  low('Faible : veille, éclairage, réfrigérateur'),
  normal('Normale pour un foyer'),
  high('Élevée : climatiseur, fer à repasser ou chauffe-eau en marche');

  const PowerLevel(this.label);

  final String label;
}

PowerLevel powerLevel(double kw) => kw < 0.8
    ? PowerLevel.low
    : kw < 2
    ? PowerLevel.normal
    : PowerLevel.high;

/// Consommation moyenne d'un jour (kWh) pour la simulation : celle du mois en cours, sinon celle
/// du mois dernier (le 1er du mois), sinon 6 kWh (compteur sans historique : valeur de démo).
double dailyAverageKwh(ConsumptionSummary summary) {
  final month = summary.thisMonth;
  if (month.daysWithData > 0 && month.dailyAverageWh > 0) return month.dailyAverageWh / 1000;
  final last = summary.lastMonth;
  if (last.daysWithData > 0 && last.consumptionWh > 0) {
    return last.consumptionWh / last.daysWithData / 1000;
  }
  return 6;
}

/// Énergie estimée depuis minuit au démarrage : la moyenne d'un jour au prorata de l'heure
/// (Brazzaville).
double energySinceMidnight(double dailyKwh, DateTime brazzavilleNow) {
  final seconds = brazzavilleNow.hour * 3600 + brazzavilleNow.minute * 60 + brazzavilleNow.second;
  return dailyKwh * seconds / 86400;
}

/// Bandeau fixé en haut de l'écran pendant la simulation (jamais caché par le défilement).
class DirectDemoBanner extends StatelessWidget {
  const DirectDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: false,
      label: 'Mode démo · simulation : valeurs simulées, rien n’est enregistré',
      excludeSemantics: true,
      child: Container(
        key: const Key('conso.directBanner'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
        color: c.warningSoft,
        child: Row(
          children: [
            AppIcon(AppIcons.info, size: 16, color: c.warningText),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(
                'Mode démo · simulation',
                style: AppText.bodySm.copyWith(color: c.warningText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu simulé de l'onglet Direct. Une valeur toutes les 2 s tant que l'onglet est affiché et
/// l'application au premier plan ; tout s'arrête à la fermeture. Rien n'est enregistré.
class DirectSimulation extends StatefulWidget {
  const DirectSimulation({
    required this.summary,
    required this.subscribedPowerVa,
    required this.now,
    this.random,
    super.key,
  });

  /// Résumé du compteur : moyenne journalière et prix de l'énergie du mois.
  final ConsumptionSummary summary;

  /// Puissance souscrite (VA), pour la jauge ; `null` : inconnue (pas de jauge).
  final int? subscribedPowerVa;

  /// Heure de Brazzaville à l'ouverture.
  final DateTime now;

  /// Hasard (fixé dans les tests).
  final Random? random;

  @override
  State<DirectSimulation> createState() => _DirectSimulationState();
}

class _DirectSimulationState extends State<DirectSimulation> {
  late final DirectSimulator _sim;
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _sim = DirectSimulator(
      averageKw: dailyAverageKwh(widget.summary) / 24,
      todayKwh: energySinceMidnight(dailyAverageKwh(widget.summary), widget.now),
      random: widget.random,
    );
    _start();
    _lifecycle = AppLifecycleListener(onShow: _start, onHide: _stop);
  }

  void _start() {
    _timer ??= Timer.periodic(directInterval, (_) => setState(_sim.tick));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Prix de l'énergie (FCFA par kWh) du mois en cours, `null` sans tarif connu.
  double? get _pricePerKwh {
    final month = widget.summary.thisMonth;
    final cost = month.energyCost;
    if (cost != null && month.consumptionWh > 0) return cost * 1000 / month.consumptionWh;
    final last = widget.summary.lastMonth;
    final lastCost = last.energyCost;
    if (lastCost != null && last.consumptionWh > 0) return lastCost * 1000 / last.consumptionWh;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kw = _sim.current;
    final level = powerLevel(kw);
    final price = _pricePerKwh;
    final va = widget.subscribedPowerVa;
    // Jauge seulement pour une puissance souscrite plausible (E²C : 3, 6, 9 kVA…).
    final percent = va == null || va < 1000 ? null : (kw * 1000 / va * 100).round();
    final levelColor = switch (level) {
      PowerLevel.low => c.successText,
      PowerLevel.normal => c.inkMuted,
      PowerLevel.high => c.warningText,
    };
    final maxY = _sim.averageKw * 3.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('conso.direct'),
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: 18),
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Space.s2,
                runSpacing: Space.s1,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: Space.s2),
                      Flexible(
                        child: Text(
                          'EN DIRECT · SIMULATION',
                          style: AppText.overline.copyWith(color: c.successText),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Actualisé toutes les 2 s',
                    style: AppText.caption.copyWith(color: c.inkFaint),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'PUISSANCE APPELÉE EN CE MOMENT',
                style: AppText.overline.copyWith(color: c.inkMuted),
              ),
              Semantics(
                // Lu à la demande, pas annoncé toutes les 2 s (ce serait épuisant).
                label: 'Puissance simulée : ${formatKw(kw)} kilowatt. ${level.label}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      key: const Key('conso.directKw'),
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formatKwValue(kw),
                            style: AppText.amountHero.copyWith(color: c.ink),
                          ),
                          TextSpan(
                            text: '${unitSpace}kW',
                            style: AppText.body.copyWith(
                              color: c.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      level.label,
                      style: AppText.bodySm.copyWith(
                        color: levelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (percent != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 10,
                    child: ColoredBox(
                      color: c.surface3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedFractionallySizedBox(
                          duration: Motion.of(context, Motion.emphasis),
                          curve: Motion.curve,
                          widthFactor: (percent / 100).clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: ColoredBox(color: percent > 45 ? c.warning : c.current),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: Space.s2,
                  children: [
                    Text('0 kW', style: AppText.caption.copyWith(color: c.inkFaint)),
                    Text(
                      '$percent$unitSpace% de la puissance souscrite '
                      '(${formatDecimal(va! / 1000, maxDecimals: 1)}${unitSpace}kVA)',
                      style: AppText.caption.copyWith(color: c.inkFaint),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Semantics(
                label: 'Courbe de la puissance simulée sur les 80 dernières secondes',
                excludeSemantics: true,
                child: SizedBox(
                  height: 90,
                  child: LineChart(
                    key: const Key('conso.directChart'),
                    duration: Motion.of(context, Motion.emphasis),
                    LineChartData(
                      minX: 0,
                      maxX: directHistory - 1,
                      minY: 0,
                      maxY: maxY,
                      lineTouchData: const LineTouchData(enabled: false),
                      titlesData: const FlTitlesData(show: false),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(bottom: BorderSide(color: c.line)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (final (i, v) in _sim.history.indexed)
                              FlSpot(i.toDouble(), v.clamp(0, maxY)),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.2,
                          color: c.current,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: c.currentSoft),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.s1),
              ExcludeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: Space.s2,
                  children: [
                    Text('Il y a 80 s', style: AppText.caption.copyWith(color: c.inkFaint)),
                    Text('Maintenant', style: AppText.caption.copyWith(color: c.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SmallCard(
                  key: const Key('conso.directToday'),
                  label: "Aujourd'hui depuis minuit",
                  value: formatKwhValue(_sim.todayKwh),
                  unit: 'kWh',
                  detail: price == null ? null : formatAboutFcfa((_sim.todayKwh * price).round()),
                ),
              ),
              const SizedBox(width: Space.s2),
              Expanded(
                child: _SmallCard(
                  key: const Key('conso.directRate'),
                  label: 'Au rythme actuel',
                  value: price == null ? '—' : formatAboutFcfa((kw * price).round()),
                  unit: price == null ? null : '/h',
                  detail: 'énergie seule',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s3),
        CustomPaint(
          foregroundPainter: _DashedBox(color: c.currentText),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s3),
            decoration: BoxDecoration(
              color: c.currentSoft,
              borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.info, size: 18, color: c.currentText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode démo : valeurs simulées. Le direct demande un compteur communicant ou '
                    'un capteur ElecPay posé sur le tableau électrique. Avec un compteur '
                    'classique, ElecPay reçoit un relevé par jour.',
                    style: AppText.bodySm.copyWith(color: c.ink),
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

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String? unit;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.inkMuted)),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppText.h2.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                ),
                if (unit != null)
                  TextSpan(
                    text: unit == '/h' ? unit : '$unitSpace$unit',
                    style: AppText.caption.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (detail != null) Text(detail!, style: AppText.caption.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}

/// Point vert qui pulse (immobile si l'utilisateur a réduit les animations).
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: c.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.success.withValues(alpha: 0.55 * (1 - _pulse.value)),
              spreadRadius: 5 * _pulse.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBox extends CustomPainter {
  const _DashedBox({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          const Radius.circular(Radii.md),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}
