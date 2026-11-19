// Outils communs des tests d'intégration (parcours rejoués SUR LE TÉLÉPHONE, contre l'API de démo
// du PC par le tunnel `adb reverse`). Lancés seulement aux jalons, par tool/integration.ps1 :
// base de démo remise à zéro avant chaque passage, API en jetons d'une minute. Jamais en CI.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:elecpay/app/app.dart';
import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/core/cache/cache_store.dart';
import 'package:elecpay/core/config/app_config.dart';
import 'package:elecpay/core/session/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// Mot de passe des comptes créés par les tests (jamais celui des comptes de démo).
const testPassword = 'Parcours2026';

/// Numéro neuf dans la plage réservée aux tests : 06 99x xx xx (la base de démo utilise 06 000 01 xx).
/// Saisie « 0699… » ; l'API l'enregistre en « +2420699… ».
String newTestPhone() => '0699${Random().nextInt(100000).toString().padLeft(5, '0')}';
String normalized(String phone) => '+242$phone';

/// L'application complète, comme au lancement, mais SANS session ni cache d'un test précédent.
Future<ProviderContainer> startApp(WidgetTester tester) async {
  // Saisie par le test (pas le clavier du téléphone : il perd des caractères, vu au jalon F3).
  binding.testTextInput.register();
  addTearDown(binding.testTextInput.unregister);
  _surfaceConverted = false; // Flutter remet la surface d'origine à la fin de chaque test
  await SecureTokenStore().clear();
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [appConfigProvider.overrideWithValue(AppConfig.fromEnvironment())],
  );
  addTearDown(container.dispose);
  await container.read(cacheStoreProvider).keepOnly(-1); // efface le cache de tous les comptes
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const ElecPayApp()),
  );
  await waitFor(tester, find.text('Connexion'));
  return container;
}

/// Attend qu'un élément apparaisse (images réelles ; jamais `pumpAndSettle` : le Splash et certains
/// boutons ont une animation sans fin).
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Pas affiché au bout de ${timeout.inSeconds} s : $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump(const Duration(milliseconds: 300)); // fin d'animation d'entrée
}

/// Touche un élément après l'avoir fait défiler à l'écran.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Saisit `text` dans le n-ième champ de l'écran.
Future<void> typeInto(WidgetTester tester, int index, String text) async {
  final field = find.byType(TextField).at(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

/// L'action du clavier (« suivant », « terminé ») sur le champ qui a le focus.
Future<void> keyboardAction(WidgetTester tester, TextInputAction action) async {
  await tester.testTextInput.receiveAction(action);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Retour Android (bouton ou geste).
Future<void> androidBack(WidgetTester tester) async {
  await binding.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 600));
}

bool _surfaceConverted = false;

/// Capture d'écran rangée par le pilote dans `build/integration/<nom>.png`.
Future<void> shot(WidgetTester tester, String name) async {
  if (!_surfaceConverted) {
    await binding.convertFlutterSurfaceToImage(); // Android : une fois par test
    _surfaceConverted = true;
  }
  await tester.pump(const Duration(milliseconds: 300));
  await binding.takeScreenshot(name);
}

/// Texte affiché (y compris dans un Text.rich) qui contient `part`.
String shownText(WidgetTester tester, String part) {
  final widget = tester.widget<RichText>(find.textContaining(part, findRichText: true).first);
  return widget.text.toPlainText();
}

/// Appels directs à l'API de démo (préparer un compte, fermer ses sessions…), par le même tunnel
/// que l'application.
class DemoApi {
  static final _root = AppConfig.fromEnvironment().apiRoot; // …/api/v1

  static Future<(int, Map<String, dynamic>?)> post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$_root$path'));
      request.headers.contentType = ContentType.json;
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      return (response.statusCode, text.isEmpty ? null : jsonDecode(text) as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }

  /// Crée un compte client (numéro saisi « 0699… ») et renvoie ses jetons.
  static Future<Map<String, dynamic>> register(
    String phone, {
    String name = 'Test Parcours',
  }) async {
    final (status, json) = await post('/auth/register', {
      'full_name': name,
      'phone': normalized(phone),
      'email': null,
      'password': testPassword,
    });
    expect(status, 201, reason: 'inscription par l’API : $json');
    return json!;
  }

  /// Se connecte (comme un autre appareil) : renvoie les jetons.
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final (status, json) = await post('/auth/login', {
      'phone': normalized(phone),
      'password': password,
    });
    expect(status, 200, reason: 'connexion par l’API : $json');
    return json!;
  }
}
