import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licenses.dart';
import 'core/config/app_config.dart';

/// Point d'entrée de l'application ElecPay (client).
///
/// La configuration est vérifiée AVANT tout : une adresse d'API invalide (ou en http dans la
/// version livrée) affiche un message clair au lieu d'une application qui échoue en silence.
void main() {
  registerFontLicenses();
  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigError catch (error) {
    runApp(ConfigErrorApp(message: error.message));
    return;
  }
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ElecPayApp(),
    ),
  );
}

/// Affichée seulement si l'application a été construite avec une mauvaise adresse d'API.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Configuration invalide : $message', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
