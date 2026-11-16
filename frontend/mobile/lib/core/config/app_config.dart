import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adresse de l'API ElecPay, donnée au LANCEMENT (jamais écrite en dur dans un écran) :
///
///     flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000        (USB + adb reverse)
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000     (Wi-Fi, IP du PC)
///     flutter build apk --dart-define=API_BASE_URL=https://api.elecpay.cg (version livrée)
///
/// Par défaut : `http://127.0.0.1:8000`, le cas « téléphone en USB avec adb reverse ».
/// La version livrée EXIGE https : c'est CE contrôle qui protège les appels de Dio (client HTTP
/// de Dart). Le manifeste Android release (`usesCleartextTraffic="false"`, vérifié par
/// `tool/apk_check.dart` en CI) protège en plus le code natif Android. Voir docs/TELEPHONE.md.
const defaultApiBaseUrl = 'http://127.0.0.1:8000';
const apiPrefix = '/api/v1';

class ConfigError implements Exception {
  const ConfigError(this.message);

  final String message;

  @override
  String toString() => 'ConfigError: $message';
}

@immutable
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// Lit `API_BASE_URL` (donnée au lancement) et la vérifie.
  factory AppConfig.fromEnvironment() => AppConfig.parse(
    const String.fromEnvironment('API_BASE_URL', defaultValue: defaultApiBaseUrl),
    release: kReleaseMode,
  );

  /// Vérifie une adresse : http(s), un hôte, rien après (« /api/v1 » est ajouté ici).
  factory AppConfig.parse(String raw, {required bool release}) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ConfigError('API_BASE_URL invalide : « $raw » (ex. https://api.elecpay.cg)');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ConfigError('API_BASE_URL doit commencer par http:// ou https:// (« $raw »)');
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw ConfigError('API_BASE_URL sans chemin : « $raw » (le préfixe /api/v1 est ajouté)');
    }
    if (release && uri.scheme != 'https') {
      throw ConfigError('La version livrée exige une API en https:// (« $raw »)');
    }
    return AppConfig(apiBaseUrl: uri.replace(path: '', query: null, fragment: null));
  }

  /// Adresse du serveur, sans chemin (ex. `http://127.0.0.1:8000`).
  final Uri apiBaseUrl;

  /// Base des routes de l'API (ex. `http://127.0.0.1:8000/api/v1`).
  String get apiRoot => '${apiBaseUrl.toString().replaceFirst(RegExp(r'/$'), '')}$apiPrefix';

  @override
  bool operator ==(Object other) => other is AppConfig && other.apiBaseUrl == apiBaseUrl;

  @override
  int get hashCode => apiBaseUrl.hashCode;
}

/// La configuration de l'application (remplacée dans les tests).
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
