import 'package:elecpay/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Taille d'écran de l'itel A05s : 720 × 1600 pixels à 2 pixels par point = 360 × 800 points.
const itelPhysicalSize = Size(720, 1600);
const itelPixelRatio = 2.0;

/// Agrandissements du texte testés (réglage « taille de police » du téléphone).
const textScales = [1.0, 1.3, 2.0];

/// Affiche `child` comme sur l'itel A05s, avec le texte agrandi `textScale` fois, dans le thème
/// donné (Nuit par défaut). Un texte qui déborde fait échouer le test (erreur « overflowed »).
Future<void> pumpOnItel(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
  ThemeData? theme,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
