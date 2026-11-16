import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/session/session_manager.dart';
import 'package:elecpay/core/session/session_providers.dart';
import 'package:elecpay/core/session/token_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tokens = SessionHarness.tokens(3);

  group('SecureTokenStore (flutter_secure_storage)', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('écrit, relit à l’identique, efface', () async {
      final store = SecureTokenStore();
      expect(await store.read(), isNull);
      await store.write(tokens);
      expect(await store.read(), tokens);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('contenu illisible : session vide et contenu effacé, sans planter', () async {
      FlutterSecureStorage.setMockInitialValues({SecureTokenStore.key: '{pas du json'});
      final store = SecureTokenStore();
      expect(await store.read(), isNull);
      expect(await const FlutterSecureStorage().read(key: SecureTokenStore.key), isNull);
    });
  });

  test('les jetons n’apparaissent jamais dans un journal (toString)', () {
    expect(tokens.toString(), isNot(contains('at-3')));
    expect(tokens.toString(), isNot(contains('rt-3')));
  });

  test('sessionStateProvider suit le gestionnaire de session', () async {
    final store = MemoryTokenStore(tokens);
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.parse('http://127.0.0.1:8000', release: false),
        ),
        tokenStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    final states = <SessionState>[];
    container.listen(sessionStateProvider, (_, next) => states.add(next), fireImmediately: true);
    await container.read(sessionManagerProvider).currentTokens();
    await container.read(sessionManagerProvider).end(SessionEndReason.expired);
    expect(states, [
      const SessionUnknown(),
      const SessionActive(42),
      const SessionEnded(SessionEndReason.expired),
    ]);
  });
}
