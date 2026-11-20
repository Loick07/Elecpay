import 'package:flutter/widgets.dart';

import 'lucide_icons.g.dart';

/// Les icônes de l'application, au trait (police Lucide EMBARQUÉE, trait de 2 px), désignées par leur
/// SENS. Les écrans utilisent ces noms, jamais `Lucide` directement : changer d'icône se fait ici.
///
/// Toutes sont des constantes : Flutter ne garde dans l'APK que les icônes réellement utilisées.
/// Nouvelle icône : l'ajouter à `lucideIcons` (tool/icons_generator.dart), puis
/// `dart run tool/generate_icons.dart`.
abstract final class AppIcons {
  // Statuts (table « Statuts » de la charte).
  static const clock = Lucide.clock;
  static const hourglass = Lucide.hourglass;
  static const check = Lucide.check;
  static const alert = Lucide.triangleAlert;
  static const cancelled = Lucide.ban;
  static const cross = Lucide.x;
  static const expired = Lucide.timerOff;
  static const question = Lucide.circleQuestionMark;

  // Champs de saisie.
  static const show = Lucide.eye;
  static const hide = Lucide.eyeOff;
  static const phone = Lucide.smartphone;
  static const back = Lucide.chevronLeft;
  static const previous = Lucide.chevronLeft;
  static const next = Lucide.chevronRight;
  static const ruleUnmet = Lucide.circle;
  static const ruleMet = Lucide.circleCheck;

  // États d'écran.
  static const empty = Lucide.inbox;
  static const error = Lucide.circleAlert;
  static const offline = Lucide.wifiOff;
  static const locked = Lucide.lock;
  static const signIn = Lucide.logIn;
  static const retry = Lucide.refreshCw;

  // Factures et paiement.
  static const bill = Lucide.fileText;
  static const energy = Lucide.zap;
  static const meter = Lucide.gauge;
  static const add = Lucide.plus;
  static const household = Lucide.house;
  static const securePay = Lucide.shieldCheck;
  static const info = Lucide.info;
  static const share = Lucide.share2;

  // Accueil : cloche des notifications, sélecteur de foyer.
  static const notifications = Lucide.bell;
  static const dropdown = Lucide.chevronDown;

  // Barre du bas (maquette : Accueil, Factures, Payer, Conso, Compte).
  static const navHome = Lucide.house;
  static const navBills = Lucide.fileText;
  static const navPay = Lucide.creditCard;
  static const navConsumption = Lucide.chartNoAxesColumn;
  static const navAccount = Lucide.user;
}

/// Tailles de la charte : 20 dans les listes, 24 dans la navigation.
abstract final class IconSizes {
  static const list = 20.0;
  static const navigation = 24.0;
}

/// Icône de l'application avec sa taille de liste par défaut et un libellé pour le lecteur d'écran
/// (`null` : icône décorative, ignorée par le lecteur d'écran).
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {this.size = IconSizes.list, this.color, this.label, super.key});

  final IconData icon;
  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color, semanticLabel: label);
}
