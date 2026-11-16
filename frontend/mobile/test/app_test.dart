import 'package:elecpay/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_health.dart';

void main() {
  testWidgets('l’application démarre sur l’écran de démarrage', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: healthOverrides(demoApi()), child: const ElecPayApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('ElecPay'), findsOneWidget);
  });
}
