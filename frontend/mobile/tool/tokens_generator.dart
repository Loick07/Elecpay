// Transforme la charte (`frontend/design/tokens.json`) en code Dart (`lib/core/theme/tokens.g.dart`).
//
// La charte reste la SEULE source : on ne recopie jamais une couleur ou une taille à la main.
// Après un changement de tokens.json : `dart run tool/generate_tokens.dart` ; le test
// `test/core/theme/tokens_test.dart` échoue tant que le fichier généré n'est pas à jour.

import 'dart:convert';

import 'package:dart_style/dart_style.dart';

/// Familles de la charte gardées dans l'application (le back-office, en Inter, est à part).
const _families = {'app': 'Poppins', 'mono': 'JetBrainsMono'};

String generateTokens(String tokensJson) {
  final json = jsonDecode(tokensJson) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln('// CODE GÉNÉRÉ depuis frontend/design/tokens.json : ne pas modifier à la main.')
    ..writeln('// Régénérer : dart run tool/generate_tokens.dart')
    ..writeln('// ignore_for_file: prefer_const_constructors, require_trailing_commas')
    ..writeln()
    ..writeln("import 'dart:ui' show FontFeature, FontVariation;")
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln();
  _colors(out, json['color'] as Map<String, dynamic>);
  _shadows(out, json['shadow'] as Map<String, dynamic>);
  _text(out, json['type'] as Map<String, dynamic>);
  _scale(out, 'Space', 'Espacements (`space-*`).', json['spacing'], 'space-', (n) => 's$n');
  _scale(out, 'Radii', 'Rayons (`radius-*`).', json['radius'], 'radius-', (n) => n);
  _blur(out, json['blur'] as Map<String, dynamic>);
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
    pageWidth: 100,
  );
  return formatter.format(out.toString());
}

// --- Couleurs -----------------------------------------------------------------------------

void _colors(StringBuffer out, Map<String, dynamic> color) {
  final tokens = (color['tokens'] as List).cast<Map<String, dynamic>>();
  String field(Map<String, dynamic> t) => _camel(t['name'] as String);
  out
    ..writeln('/// Couleurs de la charte, par thème (Nuit = `dark`, Jour = `light`).')
    ..writeln('@immutable')
    ..writeln('class ElecPayColors extends ThemeExtension<ElecPayColors> {')
    ..writeln('  const ElecPayColors({');
  for (final t in tokens) {
    out.writeln('    required this.${field(t)},');
  }
  out.writeln('  });');
  for (final theme in ['dark', 'light']) {
    out.writeln('  static const $theme = ElecPayColors(');
    for (final t in tokens) {
      final value = (t['value'] as Map<String, dynamic>)[theme] as String;
      out.writeln('    ${field(t)}: ${_color(value)},');
    }
    out.writeln('  );');
  }
  for (final t in tokens) {
    out
      ..writeln('  /// ${_oneLine(t['usage'] as String)}')
      ..writeln('  final Color ${field(t)};');
  }
  out
    ..writeln('  @override')
    ..writeln('  ElecPayColors copyWith({');
  for (final t in tokens) {
    out.writeln('    Color? ${field(t)},');
  }
  out.writeln('  }) => ElecPayColors(');
  for (final t in tokens) {
    out.writeln('    ${field(t)}: ${field(t)} ?? this.${field(t)},');
  }
  out
    ..writeln('  );')
    ..writeln('  @override')
    ..writeln('  ElecPayColors lerp(ElecPayColors? other, double t) {')
    ..writeln('    if (other == null) return this;')
    ..writeln('    return ElecPayColors(');
  for (final t in tokens) {
    out.writeln('      ${field(t)}: Color.lerp(${field(t)}, other.${field(t)}, t)!,');
  }
  out
    ..writeln('    );')
    ..writeln('  }')
    ..writeln('}')
    ..writeln();
}

// --- Ombres -------------------------------------------------------------------------------

void _shadows(StringBuffer out, Map<String, dynamic> shadow) {
  final tokens = (shadow['tokens'] as List).cast<Map<String, dynamic>>();
  String field(Map<String, dynamic> t) => _camel((t['name'] as String).replaceFirst('shadow-', ''));
  out
    ..writeln('/// Ombres de la charte, par thème.')
    ..writeln('@immutable')
    ..writeln('class ElecPayShadows extends ThemeExtension<ElecPayShadows> {')
    ..writeln('  const ElecPayShadows({');
  for (final t in tokens) {
    out.writeln('    required this.${field(t)},');
  }
  out.writeln('  });');
  for (final theme in ['dark', 'light']) {
    out.writeln('  static const $theme = ElecPayShadows(');
    for (final t in tokens) {
      final value = (t['value'] as Map<String, dynamic>)[theme] as String;
      out.writeln('    ${field(t)}: [${_boxShadow(value)}],');
    }
    out.writeln('  );');
  }
  for (final t in tokens) {
    out
      ..writeln('  /// ${_oneLine(t['usage'] as String)}')
      ..writeln('  final List<BoxShadow> ${field(t)};');
  }
  out
    ..writeln('  @override')
    ..writeln('  ElecPayShadows copyWith({');
  for (final t in tokens) {
    out.writeln('    List<BoxShadow>? ${field(t)},');
  }
  out.writeln('  }) => ElecPayShadows(');
  for (final t in tokens) {
    out.writeln('    ${field(t)}: ${field(t)} ?? this.${field(t)},');
  }
  out
    ..writeln('  );')
    ..writeln('  @override')
    ..writeln('  ElecPayShadows lerp(ElecPayShadows? other, double t) {')
    ..writeln('    if (other == null) return this;')
    ..writeln('    return ElecPayShadows(');
  for (final t in tokens) {
    out.writeln('      ${field(t)}: BoxShadow.lerpList(${field(t)}, other.${field(t)}, t)!,');
  }
  out
    ..writeln('    );')
    ..writeln('  }')
    ..writeln('}')
    ..writeln();
}

// --- Typographie --------------------------------------------------------------------------

void _text(StringBuffer out, Map<String, dynamic> type) {
  final groups = (type['groups'] as List).cast<Map<String, dynamic>>();
  out
    ..writeln(
      '/// Échelle typographique FIXE de la charte (on n’invente pas de taille intermédiaire).',
    )
    ..writeln('/// Les montants utilisent les chiffres tabulaires.')
    ..writeln('abstract final class AppText {');
  for (final group in groups) {
    final family = _families[group['family']];
    if (family == null) continue; // back-office (Inter) : pas dans l'application
    for (final style in (group['styles'] as List).cast<Map<String, dynamic>>()) {
      final size = _px(style['fontSize'] as String);
      final line = _px(style['lineHeight'] as String);
      final weight = style['fontWeight'] as int;
      final spacing = style['letterSpacing'] as String?;
      final name = style['name'] as String;
      final tabular = name.startsWith('amount') || name == 'reference';
      out
        ..writeln('  /// ${_oneLine(style['usage'] as String)}')
        ..writeln('  static const ${_camel(name)} = TextStyle(')
        ..writeln("    fontFamily: '$family',")
        ..writeln('    fontSize: ${_num(size)},')
        ..writeln('    height: ${_num(line / size)},')
        ..writeln('    fontWeight: FontWeight.w$weight,');
      if (spacing != null) {
        out.writeln('    letterSpacing: ${_num(_em(spacing) * size)},');
      }
      if (family == 'JetBrainsMono') {
        out.writeln("    fontVariations: [FontVariation('wght', $weight)],");
      }
      if (tabular) {
        out.writeln('    fontFeatures: [FontFeature.tabularFigures()],');
      }
      out.writeln('  );');
    }
  }
  out
    ..writeln('}')
    ..writeln();
}

// --- Espacements, rayons, flou ------------------------------------------------------------

void _scale(
  StringBuffer out,
  String className,
  String doc,
  Object? section,
  String prefix,
  String Function(String) name,
) {
  final tokens = ((section! as Map<String, dynamic>)['tokens'] as List)
      .cast<Map<String, dynamic>>();
  out
    ..writeln('/// $doc')
    ..writeln('abstract final class $className {');
  for (final t in tokens) {
    final key = name((t['name'] as String).replaceFirst(prefix, ''));
    out
      ..writeln('  /// ${_oneLine(t['usage'] as String)}')
      ..writeln('  static const double $key = ${_num(_px(t['value'] as String))};');
  }
  out
    ..writeln('}')
    ..writeln();
}

void _blur(StringBuffer out, Map<String, dynamic> blur) {
  final glass = (blur['tokens'] as List).cast<Map<String, dynamic>>().first;
  final px = _px(glass['value'] as String);
  out
    ..writeln('/// Flou du verre (`blur-glass`).')
    ..writeln('abstract final class Blur {')
    ..writeln('  /// Flou CSS de la charte, en pixels.')
    ..writeln('  static const double glass = ${_num(px)};')
    ..writeln('  /// Sigma Flutter équivalent (`BackdropFilter`) : la moitié du flou CSS.')
    ..writeln('  static const double glassSigma = ${_num(px / 2)};')
    ..writeln('}');
}

// --- Conversions --------------------------------------------------------------------------

String _camel(String name) {
  final parts = name.split('-');
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
}

double _px(String value) => double.parse(value.replaceAll('px', '').trim());

double _em(String value) => double.parse(value.replaceAll('em', '').trim());

String _num(double value) {
  final rounded = double.parse(value.toStringAsFixed(4));
  return rounded == rounded.roundToDouble() ? '${rounded.toInt()}' : '$rounded';
}

String _oneLine(String text) => text.replaceAll('\n', ' ');

final _rgba = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)');

String _color(String value) {
  if (value.startsWith('#') && value.length == 7) {
    return 'Color(0xFF${value.substring(1).toUpperCase()})';
  }
  final match = _rgba.firstMatch(value);
  if (match == null) throw FormatException('Couleur non reconnue dans tokens.json : $value');
  int channel(int i) => int.parse(match.group(i)!);
  final alpha = (double.parse(match.group(4)!) * 255).round();
  String hex(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  return 'Color(0x${hex(alpha)}${hex(channel(1))}${hex(channel(2))}${hex(channel(3))})';
}

String _boxShadow(String value) {
  // « 0 8px 24px rgba(0,0,0,0.35) » : décalage x, décalage y, flou, couleur.
  final colorStart = value.indexOf('rgba');
  final numbers = value.substring(0, colorStart).trim().split(RegExp(r'\s+')).map(_px).toList();
  return 'BoxShadow(offset: Offset(${_num(numbers[0])}, ${_num(numbers[1])}), '
      'blurRadius: ${_num(numbers[2])}, color: ${_color(value.substring(colorStart))})';
}
