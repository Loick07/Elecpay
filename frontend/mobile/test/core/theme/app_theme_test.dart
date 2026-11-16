import 'dart:math' as math;

import 'package:elecpay/app/app.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:elecpay/features/design_check/charte_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_health.dart';

/// Contraste WCAG entre deux couleurs opaques (1 à 21).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('correspondance de la charte : volt, current, error, surface, fond', () {
    for (final (theme, c) in [
      (AppTheme.dark, ElecPayColors.dark),
      (AppTheme.light, ElecPayColors.light),
    ]) {
      expect(theme.colorScheme.primary, c.volt);
      expect(theme.colorScheme.onPrimary, c.onVolt);
      expect(theme.colorScheme.secondary, c.current);
      expect(theme.colorScheme.error, c.error);
      expect(theme.colorScheme.surface, c.surface1);
      expect(theme.scaffoldBackgroundColor, c.bg);
      expect(theme.extension<ElecPayColors>(), c);
      expect(theme.textTheme.bodyLarge!.fontFamily, 'Poppins');
    }
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.brightness, Brightness.light);
  });

  test('contrastes de texte ≥ 4,5:1 dans les deux thèmes (charte, accessibilité)', () {
    for (final c in [ElecPayColors.dark, ElecPayColors.light]) {
      for (final (name, text, background) in [
        ('ink / bg', c.ink, c.bg),
        ('ink / surface-1', c.ink, c.surface1),
        ('ink-muted / bg', c.inkMuted, c.bg),
        ('on-volt / volt', c.onVolt, c.volt),
        ('volt-text / bg', c.voltText, c.bg),
        ('error-text / bg', c.errorText, c.bg),
        ('current-text / bg', c.currentText, c.bg),
      ]) {
        expect(contrast(text, background), greaterThanOrEqualTo(4.5), reason: name);
      }
      // ink-faint : texte d'aide, seulement sur bg et surface-1 (≥ 4,4:1 d'après la charte).
      expect(contrast(c.inkFaint, c.bg), greaterThanOrEqualTo(4.4));
      expect(contrast(c.inkFaint, c.surface1), greaterThanOrEqualTo(4.4));
    }
  });

  testWidgets('l’application démarre en thème Nuit (défaut de la charte)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: healthOverrides(demoApi()), child: const ElecPayApp()),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.text('ElecPay'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.colors.bg, ElecPayColors.dark.bg);
  });

  testWidgets('page de contrôle de la charte : Nuit puis Jour', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const CharteScreen()));
    expect(find.text('12 500 FCFA'), findsOneWidget);
    expect(find.text('EP-2026-000123'), findsOneWidget);
    Color background() =>
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
        Theme.of(tester.element(find.byType(ListView))).scaffoldBackgroundColor;
    expect(background(), ElecPayColors.dark.bg);
    await tester.tap(find.text('Nuit'));
    await tester.pumpAndSettle();
    expect(find.text('Jour'), findsOneWidget);
    expect(background(), ElecPayColors.light.bg);
  });
}
