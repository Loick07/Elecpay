// Icône et écran de lancement Android (jalon F3) : dessin d'après la maquette du Splash, éclair
// dans la zone sûre de l'icône adaptative, version monochrome, lancement navy sans flash blanc.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/launcher/launcher_art.dart';

const res = 'android/app/src/main/res';

/// Pixels visibles (alpha > 8) : leurs coordonnées.
Iterable<(int, int)> visible(Uint8List pixels, int width) sync* {
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i + 3] > 8) yield ((i ~/ 4) % width, (i ~/ 4) ~/ width);
  }
}

void main() {
  testWidgets('avant-plan adaptatif : l’éclair ENTIER dans la zone sûre (cercle de 66 dp / 108)', (
    tester,
  ) async {
    await loadLucide(tester);
    final image = await render(tester, adaptiveForeground(), sourceSize);
    final pixels = await rgba(tester, image);
    const center = sourceSize / 2;
    const safeRadius = sourceSize * adaptiveSafeDiameter / adaptiveCanvas / 2;
    final points = visible(pixels, image.width).toList();
    expect(points, isNotEmpty, reason: 'éclair dessiné (police Lucide chargée)');
    final farthest = points
        .map((p) => math.sqrt(math.pow(p.$1 + 0.5 - center, 2) + math.pow(p.$2 + 0.5 - center, 2)))
        .reduce(math.max);
    expect(farthest, lessThan(safeRadius), reason: 'jamais coupé par le masque du téléphone');
    // Et assez grand pour se voir : même place relative que sur le Splash (44 / 88).
    expect(farthest, greaterThan(safeRadius * 0.5));
  });

  testWidgets('monochrome (Android 13) : même forme, en blanc', (tester) async {
    await loadLucide(tester);
    final color = await rgba(tester, await render(tester, adaptiveForeground(), sourceSize));
    final mono = await rgba(tester, await render(tester, adaptiveMonochrome(), sourceSize));
    for (var i = 0; i < mono.length; i += 4) {
      expect(mono[i + 3], color[i + 3], reason: 'même forme (canal alpha)');
      if (mono[i + 3] > 0) expect([mono[i], mono[i + 1], mono[i + 2]], [255, 255, 255]);
    }
  });

  testWidgets('icône classique : carré jaune #F5A623, coins transparents', (tester) async {
    await loadLucide(tester);
    final image = await render(tester, legacyIcon(), sourceSize);
    final pixels = await rgba(tester, image);
    int at(int x, int y) => (y * image.width + x) * 4;
    expect(pixels[at(0, 0) + 3], 0, reason: 'coin arrondi');
    final edge = at(image.width ~/ 2, 4); // bord haut, hors de l'éclair
    expect(
      [pixels[edge], pixels[edge + 1], pixels[edge + 2], pixels[edge + 3]],
      [0xF5, 0xA6, 0x23, 0xFF],
    );
  });

  testWidgets('les images commitées sont celles du générateur (aucune retouche à la main)', (
    tester,
  ) async {
    await loadLucide(tester);
    // Comparaison des FORMES (canal alpha) avec tolérance : l'anticrénelage peut varier d'une
    // machine à l'autre, pas le dessin.
    for (final (path, art) in [
      ('assets/launcher/foreground.png', adaptiveForeground()),
      ('assets/launcher/monochrome.png', adaptiveMonochrome()),
      ('assets/launcher/icon.png', legacyIcon()),
    ]) {
      final fresh = await rgba(tester, await render(tester, art, sourceSize));
      final committed = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, sourceSize.toInt(), reason: path);
        return (await frame.image.toByteData())!.buffer.asUint8List();
      });
      var different = 0;
      for (var i = 3; i < fresh.length; i += 4) {
        if ((fresh[i] - committed![i]).abs() > 64) different++;
      }
      expect(different / (fresh.length / 4), lessThan(0.005), reason: '$path à régénérer');
    }
  });

  test('icône adaptative : fond jaune, avant-plan et monochrome sans marge ajoutée', () {
    final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
    expect(xml, contains('<monochrome>'));
    expect(RegExp(r'android:inset="0%"').allMatches(xml), hasLength(2));
    expect(File('$res/values/colors.xml').readAsStringSync(), contains('#F5A623'));
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      allOf(contains('android:label="ElecPay"'), contains('android:icon="@mipmap/ic_launcher"')),
    );
  });

  test('lancement : navy #050D1A partout, logo au centre, jamais le fond clair par défaut', () {
    expect(File('$res/values/elecpay_colors.xml').readAsStringSync(), contains('#050D1A'));
    for (final dir in ['drawable', 'drawable-v21']) {
      final xml = File('$res/$dir/launch_background.xml').readAsStringSync();
      expect(xml, allOf(contains('@color/elecpay_navy'), contains('@drawable/splash_logo')));
    }
    for (final dir in ['values', 'values-night', 'values-v31', 'values-night-v31']) {
      final xml = File('$res/$dir/styles.xml').readAsStringSync();
      expect(xml, isNot(contains('colorBackground')), reason: '$dir : fond par défaut (blanc)');
      expect(xml, contains('<item name="android:windowBackground">@color/elecpay_navy</item>'));
      if (dir.endsWith('v31')) {
        expect(xml, contains('windowSplashScreenBackground">@color/elecpay_navy'));
        expect(xml, contains('windowSplashScreenAnimatedIcon">@drawable/splash_icon'));
      }
    }
    for (final logo in ['splash_logo.png', 'splash_icon.png']) {
      expect(File('$res/drawable-xxxhdpi/$logo').existsSync(), isTrue, reason: logo);
    }
  });
}
