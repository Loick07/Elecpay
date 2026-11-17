import 'package:elecpay/core/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Duration> durationIn(WidgetTester tester, {required bool reduce}) async {
  late Duration result;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Builder(
        builder: (context) {
          result = Motion.of(context, Motion.appear);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  test('durées de la charte : 150, 250, 400 ms, courbe ease-out', () {
    expect(Motion.press, const Duration(milliseconds: 150));
    expect(Motion.appear, const Duration(milliseconds: 250));
    expect(Motion.emphasis, const Duration(milliseconds: 400));
    expect(Motion.curve, Curves.easeOut);
  });

  testWidgets('animations réduites par le téléphone : tout apparaît sans mouvement', (
    tester,
  ) async {
    expect(await durationIn(tester, reduce: true), Duration.zero);
    expect(await durationIn(tester, reduce: false), Motion.appear);
  });
}
