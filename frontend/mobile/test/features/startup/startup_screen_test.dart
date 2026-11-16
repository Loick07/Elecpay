import 'package:elecpay/app/app.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_health.dart';

Future<FakeHealthService> start(WidgetTester tester, ApiHealth answer) async {
  final service = FakeHealthService(answer);
  await tester.pumpWidget(
    ProviderScope(overrides: healthOverrides(service), child: const ElecPayApp()),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('API joignable en mode démo : badge « Mode démo »', (tester) async {
    await start(tester, const ApiReachable(demoMode: true, databaseOk: true));
    expect(find.text('API joignable'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsOneWidget);
  });

  testWidgets('hors mode démo : pas de badge', (tester) async {
    await start(tester, const ApiReachable(demoMode: false, databaseOk: true));
    expect(find.text('API joignable'), findsOneWidget);
    expect(find.text('MODE DÉMO'), findsNothing);
  });

  testWidgets('base injoignable côté serveur : message clair', (tester) async {
    await start(tester, const ApiReachable(demoMode: true, databaseOk: false));
    expect(find.textContaining('momentanément indisponible'), findsOneWidget);
  });

  testWidgets('API injoignable : aide (adb reverse) et Réessayer', (tester) async {
    final service = await start(tester, const ApiUnreachable('http://127.0.0.1:8000'));
    expect(find.textContaining('Impossible de joindre ElecPay'), findsOneWidget);
    expect(find.textContaining('adb reverse tcp:8000 tcp:8000'), findsOneWidget);
    expect(service.calls, 1);

    service.answer = const ApiReachable(demoMode: true, databaseOk: true);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('API joignable'), findsOneWidget);
  });
}
