import 'package:flutter_test/flutter_test.dart';

import '../../tool/apk_check.dart';

/// Extraits réels de `aapt2 dump xmltree` sur les APK construits le 16/11/2026.
const _attribute = 'A: http://schemas.android.com/apk/res/android:usesCleartextTraffic(0x010104ec)';

void main() {
  test('APK release : HTTP en clair interdit', () {
    expect(cleartextFromXmlTree('E: application\n        $_attribute=false\n'), isFalse);
  });

  test('APK debug / profile : HTTP en clair permis', () {
    const debuggable = 'A: http://schemas.android.com/apk/res/android:debuggable(0x0101000f)=true';
    expect(cleartextFromXmlTree('$debuggable\n$_attribute=true\n'), isTrue);
  });

  test('attribut absent : signalé (null), jamais pris pour « interdit »', () {
    expect(cleartextFromXmlTree('E: application\n'), isNull);
  });

  test('taille affichée en Mo, à la française', () {
    expect(formatSize(15099494), '14,4 Mo');
  });
}
