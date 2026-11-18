import 'package:elecpay/core/demo/demo_mode.dart';
import 'package:elecpay/core/network/api_health.dart';
import 'package:elecpay/core/widgets/demo_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_auth_backend.dart';
import '../../support/fake_health.dart';

/// Le mode démo après la lecture de la valeur gardée et la vérification de l'API.
Future<(DemoMode, MemoryDemoModeStore)> settle({
  required bool? stored,
  required FakeHealthService health,
}) async {
  final store = MemoryDemoModeStore(stored);
  final container = ProviderContainer(
    overrides: [...healthOverrides(health), demoModeStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  container.read(demoModeProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return (container.read(demoModeProvider), store);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('on ne sait pas encore : badge AFFICHÉ par défaut', () {
    expect(const DemoMode(null).showBadge, isTrue);
    expect(const DemoMode(true).showBadge, isTrue);
    expect(const DemoMode(false).showBadge, isFalse);
  });

  test('jamais su et API muette : badge affiché', () async {
    final (demo, _) = await settle(stored: null, health: silentApi());
    expect(demo.showBadge, isTrue);
  });

  test('hors ligne : la dernière valeur connue est gardée (ici : pas en démo)', () async {
    final (demo, _) = await settle(stored: false, health: unreachableApi());
    expect(demo.known, isFalse);
    expect(demo.showBadge, isFalse);
  });

  test('hors ligne, dernière valeur « démo » : badge affiché', () async {
    final (demo, _) = await settle(stored: true, health: unreachableApi());
    expect(demo.showBadge, isTrue);
  });

  test('l’API répond : sa valeur l’emporte et elle est gardée pour la prochaine fois', () async {
    final (demo, store) = await settle(
      stored: true,
      health: FakeHealthService(const ApiReachable(demoMode: false, databaseOk: true)),
    );
    expect(demo.known, isFalse);
    expect(store.value, isFalse);

    final (demo2, store2) = await settle(stored: null, health: demoApi());
    expect(demo2.known, isTrue);
    expect(store2.value, isTrue);
  });

  group('stockage sur le téléphone', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('écrit puis relit la dernière valeur', () async {
      final store = SecureDemoModeStore();
      expect(await store.read(), isNull);
      await store.write(false);
      expect(await store.read(), isFalse);
      await store.write(true);
      expect(await store.read(), isTrue);
    });

    test('valeur illisible : « on ne sait pas » (badge affiché)', () async {
      FlutterSecureStorage.setMockInitialValues({SecureDemoModeStore.key: 'peut-être'});
      expect(await SecureDemoModeStore().read(), isNull);
    });
  });

  group('arrivée DIRECTE sur l’accueil (session enregistrée)', () {
    testWidgets('API injoignable, jamais su : badge affiché sur l’accueil', (tester) async {
      await AppHarness(stored: SessionHarness.tokens(1), health: unreachableApi()).start(tester);
      await tester.pumpAndSettle();
      expect(find.text('Accueil : bientôt'), findsOneWidget);
      expect(find.byType(DemoBadge), findsOneWidget);
    });

    testWidgets('API injoignable, dernière valeur « démo » : badge affiché', (tester) async {
      await AppHarness(
        stored: SessionHarness.tokens(1),
        health: unreachableApi(),
        storedDemoMode: true,
      ).start(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsOneWidget);
    });

    testWidgets('API joignable en démo : badge affiché, valeur gardée', (tester) async {
      final h = AppHarness(stored: SessionHarness.tokens(1));
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsOneWidget);
      expect(h.demoStore.value, isTrue);
    });

    testWidgets('API réelle (hors démo) : pas de badge', (tester) async {
      final h = AppHarness(
        stored: SessionHarness.tokens(1),
        health: FakeHealthService(const ApiReachable(demoMode: false, databaseOk: true)),
      );
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsNothing);
      expect(h.demoStore.value, isFalse);
    });

    testWidgets('API réelle répondant APRÈS l’arrivée : le badge disparaît alors', (tester) async {
      final health = silentApi();
      final h = AppHarness(stored: SessionHarness.tokens(1), health: health);
      await h.start(tester);
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsOneWidget, reason: 'on ne sait pas encore');

      health
        ..hang = false
        ..answer = const ApiReachable(demoMode: false, databaseOk: true);
      await AppHarness.containerOf(tester).read(demoModeProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.byType(DemoBadge), findsNothing);
    });
  });
}
