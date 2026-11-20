// FICHIER TEMPORAIRE (mesure) : jamais commité.
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'zz_capture_tmp_test.dart' show loadFonts;

void main() {
  testWidgets('mesure', (tester) async {
    await tester.runAsync(loadFonts);
    for (final w in [FontWeight.w500, FontWeight.w600]) {
      for (final label in ['Direct', 'Jour', 'Semaine', 'Mois', 'Année']) {
        final p = TextPainter(
          text: TextSpan(text: label, style: AppText.bodySm.copyWith(fontWeight: w)),
          textDirection: TextDirection.ltr,
        )..layout();
        debugPrint('$w $label ${p.width} (fontSize ${AppText.bodySm.fontSize})');
      }
    }
  });
}
