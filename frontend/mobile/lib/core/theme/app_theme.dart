import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Les thèmes Nuit (défaut) et Jour, construits UNIQUEMENT depuis les tokens de la charte
/// (`tokens.g.dart`, généré depuis `frontend/design/tokens.json`).
///
/// Correspondance (CHARTE.md, « Correspondance Flutter ») : `bg` → fond des écrans, `volt` →
/// `primary`, `current` → `secondary`, `error` → `error`, `surface-1` → `surface`. Les autres
/// couleurs se lisent avec `context.colors` (ThemeExtension `ElecPayColors`).
abstract final class AppTheme {
  static ThemeData get dark => _build(Brightness.dark, ElecPayColors.dark, ElecPayShadows.dark);

  static ThemeData get light => _build(Brightness.light, ElecPayColors.light, ElecPayShadows.light);

  static ThemeData _build(Brightness brightness, ElecPayColors c, ElecPayShadows shadows) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.volt,
      onPrimary: c.onVolt,
      secondary: c.current,
      onSecondary: c.onCurrent,
      error: c.error,
      onError: c.onCurrent,
      surface: c.surface1,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerHighest: c.surface2,
      outline: c.line,
      outlineVariant: c.line,
    );
    final text = _textTheme(c);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: 'Poppins',
      textTheme: text,
      dividerColor: c.line,
      extensions: [c, shadows],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.h1.copyWith(color: c.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.volt,
          foregroundColor: c.onVolt,
          minimumSize: const Size(Space.s12, Space.s12),
          textStyle: AppText.bodyStrong,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Radii.md)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface1,
        hintStyle: AppText.body.copyWith(color: c.inkFaint),
        border: _border(c.line),
        enabledBorder: _border(c.line),
        focusedBorder: _border(c.focus, width: 2),
        errorBorder: _border(c.error),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
    borderSide: BorderSide(color: color, width: width),
  );

  /// Échelle de la charte rangée dans les emplacements Material (pour les widgets standards).
  static TextTheme _textTheme(ElecPayColors c) {
    TextStyle ink(TextStyle style) => style.copyWith(color: c.ink);
    TextStyle muted(TextStyle style) => style.copyWith(color: c.inkMuted);
    return TextTheme(
      displayLarge: ink(AppText.amountHero),
      displayMedium: ink(AppText.display),
      headlineLarge: ink(AppText.display),
      headlineMedium: ink(AppText.h1),
      titleLarge: ink(AppText.h1),
      titleMedium: ink(AppText.h2),
      titleSmall: ink(AppText.bodyStrong),
      bodyLarge: ink(AppText.body),
      bodyMedium: ink(AppText.body),
      bodySmall: muted(AppText.bodySm),
      labelLarge: ink(AppText.bodyStrong),
      labelMedium: muted(AppText.caption),
      labelSmall: muted(AppText.overline),
    );
  }
}

/// Accès court aux couleurs et ombres de la charte : `context.colors.volt`.
extension ElecPayThemeContext on BuildContext {
  ElecPayColors get colors => Theme.of(this).extension<ElecPayColors>()!;
  ElecPayShadows get shadows => Theme.of(this).extension<ElecPayShadows>()!;
}
