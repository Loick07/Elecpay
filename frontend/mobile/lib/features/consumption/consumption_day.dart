import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import 'consumption_rules.dart';

// Vue Jour de l'écran 11 : calendrier coloré du mois (D7.3) et carte du jour.

/// Opacité du bleu `current` pour chaque niveau (du plus pâle au plus soutenu).
double _alpha(DayLevel level) => switch (level) {
  DayLevel.low => 0.18,
  DayLevel.normal => 0.42,
  DayLevel.high => 0.68,
  DayLevel.veryHigh => 0.95,
};

/// Le texte passe en blanc sur les bleus soutenus (contraste).
bool _strong(DayLevel level) => level == DayLevel.high || level == DayLevel.veryHigh;

/// Calendrier du mois : chaque jour coloré selon son niveau, estimé en pointillé orange, jour
/// affiché cerclé de jaune. TalkBack lit « 14 novembre, 9 kWh, consommation normale ».
class DayCalendar extends StatelessWidget {
  const DayCalendar({required this.cells, required this.onSelect, super.key});

  final List<CalendarCell> cells;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = <List<CalendarCell?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add([for (var j = i; j < i + 7; j++) j < cells.length ? cells[j] : null]);
    }
    return Container(
      key: const Key('conso.calendar'),
      padding: const EdgeInsets.all(Space.s3),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (final d in _weekdays)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        d,
                        maxLines: 1,
                        style: AppText.caption.copyWith(
                          color: c.inkMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s1),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, cell) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: Space.s1),
                      Expanded(
                        child: cell?.day == null
                            ? const SizedBox(height: 44)
                            : _DayCell(cell: cell!, onTap: () => onSelect(cell.day!)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.s1),
          const CalendarLegend(),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.cell, required this.onTap});

  final CalendarCell cell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final level = cell.level;
    final fill = level == null ? c.surface2 : c.current.withValues(alpha: _alpha(level));
    final ink = level == null ? c.inkFaint : (_strong(level) ? c.onCurrent : c.ink);
    const radius = BorderRadius.all(Radius.circular(10));
    Widget content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: cell.selected ? Border.all(color: c.volt, width: 2) : null,
        boxShadow: cell.selected ? [BoxShadow(color: c.voltSoft, spreadRadius: 3)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${cell.day!.day}',
            style: AppText.caption.copyWith(color: ink, fontWeight: FontWeight.w600),
          ),
          if (cell.hasData)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCellValue(cell.wh),
                maxLines: 1,
                style: AppText.caption.copyWith(
                  color: ink.withValues(alpha: 0.85),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
    if (cell.estimated && !cell.selected) {
      content = CustomPaint(
        foregroundPainter: DashedBorderPainter(color: c.warning, radius: 10),
        child: content,
      );
    }
    return Semantics(
      button: cell.hasData,
      selected: cell.selected,
      label: cell.spoken,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('conso.day.${cell.day!.day}'),
        behavior: HitTestBehavior.opaque,
        onTap: cell.hasData ? onTap : null,
        child: content,
      ),
    );
  }
}

/// Valeur d'une case : « 9 », « 12,4 » (kWh, sans l'unité, faute de place).
String formatCellValue(int wh) {
  final tenths = (wh / 100).round();
  return tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10},${tenths % 10}';
}

/// Légende du calendrier : les 4 niveaux nommés, et l'estimation en pointillé (D7.3).
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppText.caption.copyWith(color: c.inkFaint);
    Widget item(Widget swatch, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: Space.s1),
        Text(label, style: style),
      ],
    );
    Widget box(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
    return Semantics(
      container: true,
      label:
          'Légende : couleur du jour par rapport à la moyenne du mois, de faible à très élevée ; '
          'pointillé : estimation',
      excludeSemantics: true,
      child: Wrap(
        key: const Key('conso.calendarLegend'),
        alignment: WrapAlignment.center,
        spacing: Space.s3,
        runSpacing: Space.s1,
        children: [
          for (final level in DayLevel.values)
            item(box(c.current.withValues(alpha: _alpha(level))), level.label),
          item(
            CustomPaint(
              foregroundPainter: DashedBorderPainter(color: c.warning, radius: 3),
              child: const SizedBox(width: 12, height: 12),
            ),
            'Estimation',
          ),
        ],
      ),
    );
  }
}

/// Bordure en pointillé arrondie (Flutter n'en a pas) : jours estimés.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color || old.radius != radius;
}

/// Carte du jour : titre, badge Relevé / Estimation, index de début et de fin, moyenne du même
/// jour de la semaine, classement du mois, note.
class DayDetailCard extends StatelessWidget {
  const DayDetailCard({required this.card, super.key});

  final DayCard card;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget field(String label, String value) => Semantics(
      container: true,
      label: '$label : $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.inkMuted)),
          Text(
            value,
            style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
    return Container(
      key: const Key('conso.dayCard'),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
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
              Semantics(
                header: true,
                child: Text(
                  card.title,
                  style: AppText.bodyStrong.copyWith(color: c.ink, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 3),
                decoration: BoxDecoration(
                  color: card.estimated ? c.warningSoft : c.currentSoft,
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
                ),
                child: Text(
                  card.badge,
                  style: AppText.caption.copyWith(
                    color: card.estimated ? c.warningText : c.currentText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field('Index de début', card.indexStart)),
              const SizedBox(width: Space.s3),
              Expanded(child: field('Index de fin', card.indexEnd)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field(card.averageLabel, card.average)),
              const SizedBox(width: Space.s3),
              Expanded(child: field('Classement du mois', card.rank)),
            ],
          ),
          const SizedBox(height: 10),
          Text(card.note, style: AppText.caption.copyWith(color: c.inkFaint)),
        ],
      ),
    );
  }
}
