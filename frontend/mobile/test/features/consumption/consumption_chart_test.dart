import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/features/consumption/consumption_chart.dart';
import 'package:elecpay/features/consumption/consumption_rules.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/itel_screen.dart';

ChartBar bar(int wh, {bool hasData = true}) => (
  wh: wh,
  hasData: hasData,
  estimated: false,
  axis: '',
  value: null,
  spoken: '$wh Wh',
  target: null,
);

void main() {
  // Défaut vu au jalon F4 → F7 sur l'itel : un jour RELEVÉ à 0 kWh (boutique fermée) était une barre
  // de hauteur nulle, invisible, impossible à distinguer d'un trou.
  testWidgets('jour relevé à 0 kWh : petite barre bleue, distincte du trait gris sans relevé', (
    tester,
  ) async {
    await pumpOnItel(
      tester,
      ConsumptionBars(
        bars: [bar(9000), bar(0), bar(0, hasData: false)],
        label: 'test',
        hint: 'test',
        onSelect: (_) {},
      ),
    );
    final context = tester.element(find.byType(ConsumptionBars));
    final c = context.colors;
    final rods = [
      for (final g in tester.widget<BarChart>(find.byType(BarChart)).data.barGroups)
        g.barRods.single,
    ];
    expect(rods[0].toY, 9);
    // Relevé à 0 kWh : visible (3 points de haut sur 150) et BLEU.
    expect(rods[1].toY, closeTo(9 * 3 / chartHeight, 1e-9));
    expect(rods[1].color, c.current);
    // Sans relevé : même hauteur, mais GRIS.
    expect(rods[2].toY, rods[1].toY);
    expect(rods[2].color, c.surface3);
  });
}
