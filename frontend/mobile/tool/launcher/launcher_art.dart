// Dessin de l'icône ElecPay et du logo de lancement, d'après la maquette du Splash
// (frontend/design/maquettes/client/sources/Splash.dc.html) : éclair Lucide « zap » (le même
// glyphe que l'écran Splash, AppIcons.energy) sur un carré jaune aux coins arrondis.
//
// Partagé par le générateur (tool/launcher/generate_launcher_images_test.dart) et par les tests
// (test/tool/launcher_icon_test.dart). Rien n'est dessiné à la main : tout vient de la police
// Lucide embarquée et des couleurs de la charte (tokens.g.dart).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elecpay/core/theme/app_icons.dart';
import 'package:elecpay/core/theme/tokens.g.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Couleurs de la charte (thème Nuit) : jaune ElecPay, éclair posé dessus, fond navy.
final volt = ElecPayColors.dark.volt; // #F5A623
final onVolt = ElecPayColors.dark.onVolt;
final navy = ElecPayColors.dark.bg; // #050D1A

/// Proportions de la maquette du Splash : carré de 88, coins de 28 (Radii.xl), éclair de 44.
const splashSquare = 88.0;
const iconRatio = 44 / splashSquare; // éclair / carré
const cornerRatio = Radii.xl / splashSquare; // rayon des coins / carré

/// Icône adaptative Android : toile de 108 dp, partie visible 72 dp, zone sûre (jamais coupée
/// par le masque) : cercle de 66 dp.
const adaptiveCanvas = 108.0;
const adaptiveVisible = 72.0;
const adaptiveSafeDiameter = 66.0;

/// Taille des images sources (flutter_launcher_icons en tire toutes les densités).
const sourceSize = 1024.0;

/// Écran de lancement Android 12+ : toile de 288 dp, logo de 88 dp au centre (même taille que le
/// carré de l'écran Splash Flutter, qui prend le relais sans saut de taille).
const splashIconCanvasDp = 288.0;

/// Les images de lancement sont rangées en xxxhdpi (4 pixels par dp).
const xxxhdpi = 4.0;

Widget _zap(double size, Color color) => Icon(AppIcons.energy, size: size, color: color);

/// Carré jaune aux coins arrondis avec l'éclair : le logo de la maquette, à la taille `side`.
Widget logoSquare(double side) => Container(
  width: side,
  height: side,
  alignment: Alignment.center,
  decoration: BoxDecoration(color: volt, borderRadius: BorderRadius.circular(side * cornerRatio)),
  child: _zap(side * iconRatio, onVolt),
);

/// Icône classique (avant Android 8) : le logo sur toute la surface, coins transparents.
Widget legacyIcon() => logoSquare(sourceSize);

/// Avant-plan de l'icône adaptative : l'éclair seul, à la taille qu'il a dans le logo, rapportée à
/// la partie visible (72 dp sur 108). Le fond jaune est une couleur (adaptive_icon_background).
double adaptiveZapSize() => sourceSize * (adaptiveVisible / adaptiveCanvas) * iconRatio;

Widget adaptiveForeground() => Center(child: _zap(adaptiveZapSize(), onVolt));

/// Version monochrome (Android 13, icônes à thème) : seule la forme compte (canal alpha).
Widget adaptiveMonochrome() => Center(child: _zap(adaptiveZapSize(), const Color(0xFFFFFFFF)));

/// Logo de l'écran de lancement Android 12+ (toile transparente de 288 dp, logo de 88 dp).
Widget splashIcon() => Center(child: logoSquare(splashSquare * xxxhdpi));

/// Charge la police Lucide embarquée (les tests ne chargent pas les polices de l'application).
Future<void> loadLucide(WidgetTester tester) => tester.runAsync(() async {
  final bytes = File('assets/fonts/Lucide.ttf').readAsBytesSync();
  final loader = FontLoader('Lucide')..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
});

/// Dessine `art` dans une image carrée de `size` pixels (fond transparent).
Future<ui.Image> render(WidgetTester tester, Widget art, double size) async {
  tester.view.physicalSize = Size(size, size);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(width: size, height: size, child: art),
        ),
      ),
    ),
  );
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(boundary.toImage))!;
}

/// L'image au format PNG.
Future<Uint8List> png(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
  return data!.buffer.asUint8List();
}

/// Les pixels bruts (RGBA, 4 octets par pixel), couleur NON prémultipliée par l'opacité.
Future<Uint8List> rgba(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
  );
  return data!.buffer.asUint8List();
}
