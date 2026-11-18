import 'package:elecpay/features/startup/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/fake_health.dart';

void main() {
  testWidgets('l’application démarre sur le splash', (tester) async {
    await AppHarness(health: silentApi()).start(tester);
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ElecPay'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // fin du délai du splash
  });
}
