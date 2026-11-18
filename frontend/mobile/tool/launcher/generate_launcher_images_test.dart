// Génère les images de l'icône et du lancement Android (à relancer si le logo change) :
//
//   flutter test tool/launcher/generate_launcher_images_test.dart
//   dart run flutter_launcher_icons        (configuration : flutter_launcher_icons.yaml)
//
// Écrit :
// - assets/launcher/icon.png, foreground.png, monochrome.png : sources de flutter_launcher_icons ;
// - android/app/src/main/res/drawable-xxxhdpi/splash_icon.png : logo de l'écran de lancement
//   Android 12+ ; splash_logo.png : le même logo pour Android 7 à 11 (launch_background.xml).
//
// Un test (et pas un simple programme) car le dessin a besoin du moteur de rendu de Flutter.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'launcher_art.dart';

void main() {
  final outputs = <String, (Widget Function(), double)>{
    'assets/launcher/icon.png': (legacyIcon, sourceSize),
    'assets/launcher/foreground.png': (adaptiveForeground, sourceSize),
    'assets/launcher/monochrome.png': (adaptiveMonochrome, sourceSize),
    'android/app/src/main/res/drawable-xxxhdpi/splash_icon.png': (
      splashIcon,
      splashIconCanvasDp * xxxhdpi,
    ),
    'android/app/src/main/res/drawable-xxxhdpi/splash_logo.png': (
      () => logoSquare(splashSquare * xxxhdpi),
      splashSquare * xxxhdpi,
    ),
  };

  for (final MapEntry(key: path, value: (art, size)) in outputs.entries) {
    testWidgets('génère $path', (tester) async {
      await loadLucide(tester);
      final image = await render(tester, art(), size);
      final file = File(path)..createSync(recursive: true);
      file.writeAsBytesSync(await png(tester, image));
      // ignore: avoid_print
      print('écrit : $path (${image.width} × ${image.height})');
    });
  }
}
