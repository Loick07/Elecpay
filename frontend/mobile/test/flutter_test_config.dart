import 'dart:async';
import 'dart:io';

/// Lancé avant chaque fichier de test : AUCUN test n'a le droit d'ouvrir une vraie connexion
/// réseau (par exemple vers l'API locale du PC). Les tests passent par de faux serveurs
/// (`test/support/fake_server.dart`) ; un oubli échoue ici au lieu de réussir par hasard.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HttpOverrides.global = _NoRealNetwork();
  await testMain();
}

class _NoRealNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => throw StateError(
    'Test : accès au réseau réel interdit. Brancher un FakeServer (test/support/fake_server.dart).',
  );
}
