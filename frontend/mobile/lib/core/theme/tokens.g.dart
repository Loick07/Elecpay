// CODE GÉNÉRÉ depuis frontend/design/tokens.json : ne pas modifier à la main.
// Régénérer : dart run tool/generate_tokens.dart
// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'dart:ui' show FontFeature, FontVariation;

import 'package:flutter/material.dart';

/// Couleurs de la charte, par thème (Nuit = `dark`, Jour = `light`).
@immutable
class ElecPayColors extends ThemeExtension<ElecPayColors> {
  const ElecPayColors({
    required this.bg,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.glass,
    required this.glassStrong,
    required this.glassBorder,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.volt,
    required this.voltPress,
    required this.voltSoft,
    required this.voltText,
    required this.onVolt,
    required this.current,
    required this.currentText,
    required this.currentSoft,
    required this.onCurrent,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorText,
    required this.errorSoft,
    required this.focus,
  });
  static const dark = ElecPayColors(
    bg: Color(0xFF050D1A),
    surface1: Color(0xFF0A1628),
    surface2: Color(0xFF102038),
    surface3: Color(0xFF18304F),
    glass: Color(0x0FFFFFFF),
    glassStrong: Color(0xC7102038),
    glassBorder: Color(0x1FFFFFFF),
    line: Color(0xFF1C2E48),
    ink: Color(0xFFF2F5FA),
    inkMuted: Color(0xFF9AA8BD),
    inkFaint: Color(0xFF7586A0),
    volt: Color(0xFFF5A623),
    voltPress: Color(0xFFD98E0F),
    voltSoft: Color(0x24F5A623),
    voltText: Color(0xFFF5A623),
    onVolt: Color(0xFF1A1203),
    current: Color(0xFF1E88E5),
    currentText: Color(0xFF4DA3F0),
    currentSoft: Color(0x291E88E5),
    onCurrent: Color(0xFFFFFFFF),
    success: Color(0xFF22C55E),
    successSoft: Color(0x2422C55E),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0x24F59E0B),
    error: Color(0xFFEF4444),
    errorText: Color(0xFFF87171),
    errorSoft: Color(0x24EF4444),
    focus: Color(0xFF4DA3F0),
  );
  static const light = ElecPayColors(
    bg: Color(0xFFF3F6FA),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFE9EEF5),
    surface3: Color(0xFFDCE4EE),
    glass: Color(0xB8FFFFFF),
    glassStrong: Color(0xE0FFFFFF),
    glassBorder: Color(0x1A0A1628),
    line: Color(0xFFD5DDE8),
    ink: Color(0xFF0A1628),
    inkMuted: Color(0xFF4A5A70),
    inkFaint: Color(0xFF5F6F86),
    volt: Color(0xFFF5A623),
    voltPress: Color(0xFFD98E0F),
    voltSoft: Color(0x2EF5A623),
    voltText: Color(0xFF9A5B00),
    onVolt: Color(0xFF1A1203),
    current: Color(0xFF1565C0),
    currentText: Color(0xFF1565C0),
    currentSoft: Color(0x1F1565C0),
    onCurrent: Color(0xFFFFFFFF),
    success: Color(0xFF15803D),
    successSoft: Color(0x1F15803D),
    warning: Color(0xFFB45309),
    warningSoft: Color(0x1FB45309),
    error: Color(0xFFB91C1C),
    errorText: Color(0xFFB91C1C),
    errorSoft: Color(0x1AB91C1C),
    focus: Color(0xFF1565C0),
  );

  /// Fond de page de l'app et du back-office. Le bleu nuit est l'identité d'ElecPay : on le garde dès le splash.
  final Color bg;

  /// Cartes opaques, listes, champs de saisie posés sur bg.
  final Color surface1;

  /// Éléments en relief dans une carte : ligne survolée, piste d'un graphique, segment inactif.
  final Color surface2;

  /// Squelettes de chargement et pistes de barres de progression.
  final Color surface3;

  /// Remplissage verre (avec flou 24px) : barre de navigation, carte héros du tableau de bord, feuilles du bas. Jamais pour du texte long.
  final Color glass;

  /// Verre plus opaque quand le contenu derrière bouge beaucoup (barre de navigation au-dessus d'un graphique).
  final Color glassStrong;

  /// Liseré 1px de toute surface en verre ; c'est lui qui donne l'effet « vitre ».
  final Color glassBorder;

  /// Séparateurs et bordures de champs au repos.
  final Color line;

  /// Texte principal et montants.
  final Color ink;

  /// Texte secondaire : libellés, dates, unités (kWh, FCFA).
  final Color inkMuted;

  /// Texte d'aide et placeholders, uniquement sur bg ou surface-1 (≥ 4,4:1).
  final Color inkFaint;

  /// Jaune ElecPay : action principale (bouton Payer, onglet Payer, CTA). Un seul élément volt par écran autant que possible. Jamais pour un statut.
  final Color volt;

  /// État pressé d'un bouton volt.
  final Color voltPress;

  /// Fond doux autour d'un élément volt (puce sélectionnée, halo de l'onglet Payer).
  final Color voltSoft;

  /// Jaune utilisé comme texte ou icône (lien d'action, montant mis en avant).
  final Color voltText;

  /// Texte et icônes posés sur volt (9,1:1).
  final Color onVolt;

  /// Bleu « courant » : données de consommation (barres, courbes), liens d'information, focus.
  final Color current;

  /// Bleu utilisé comme texte sur bg ou surfaces.
  final Color currentText;

  /// Fond des puces d'information, zone sous la courbe de consommation, badge Mode démo.
  final Color currentSoft;

  /// Texte sur un aplat current (5,7:1 sur le bleu clair, réservé aux gros textes sur #1E88E5).
  final Color onCurrent;

  /// Payée, paiement réussi, consommation en baisse.
  final Color success;

  /// Fond des badges de succès.
  final Color successSoft;

  /// Échéance proche, consommation estimée, statut inconnu. Proche du jaune volt : toujours avec une icône et un libellé, jamais seul.
  final Color warning;

  /// Fond des badges d'alerte.
  final Color warningSoft;

  /// Aplat d'erreur (icône, bordure de champ invalide).
  final Color error;

  /// Texte d'erreur : impayée en retard, paiement échoué, message de champ.
  final Color errorText;

  /// Fond des badges et bannières d'erreur.
  final Color errorSoft;

  /// Anneau de focus 2px (clavier, back-office).
  final Color focus;
  @override
  ElecPayColors copyWith({
    Color? bg,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? glass,
    Color? glassStrong,
    Color? glassBorder,
    Color? line,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? volt,
    Color? voltPress,
    Color? voltSoft,
    Color? voltText,
    Color? onVolt,
    Color? current,
    Color? currentText,
    Color? currentSoft,
    Color? onCurrent,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorText,
    Color? errorSoft,
    Color? focus,
  }) => ElecPayColors(
    bg: bg ?? this.bg,
    surface1: surface1 ?? this.surface1,
    surface2: surface2 ?? this.surface2,
    surface3: surface3 ?? this.surface3,
    glass: glass ?? this.glass,
    glassStrong: glassStrong ?? this.glassStrong,
    glassBorder: glassBorder ?? this.glassBorder,
    line: line ?? this.line,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkFaint: inkFaint ?? this.inkFaint,
    volt: volt ?? this.volt,
    voltPress: voltPress ?? this.voltPress,
    voltSoft: voltSoft ?? this.voltSoft,
    voltText: voltText ?? this.voltText,
    onVolt: onVolt ?? this.onVolt,
    current: current ?? this.current,
    currentText: currentText ?? this.currentText,
    currentSoft: currentSoft ?? this.currentSoft,
    onCurrent: onCurrent ?? this.onCurrent,
    success: success ?? this.success,
    successSoft: successSoft ?? this.successSoft,
    warning: warning ?? this.warning,
    warningSoft: warningSoft ?? this.warningSoft,
    error: error ?? this.error,
    errorText: errorText ?? this.errorText,
    errorSoft: errorSoft ?? this.errorSoft,
    focus: focus ?? this.focus,
  );
  @override
  ElecPayColors lerp(ElecPayColors? other, double t) {
    if (other == null) return this;
    return ElecPayColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      volt: Color.lerp(volt, other.volt, t)!,
      voltPress: Color.lerp(voltPress, other.voltPress, t)!,
      voltSoft: Color.lerp(voltSoft, other.voltSoft, t)!,
      voltText: Color.lerp(voltText, other.voltText, t)!,
      onVolt: Color.lerp(onVolt, other.onVolt, t)!,
      current: Color.lerp(current, other.current, t)!,
      currentText: Color.lerp(currentText, other.currentText, t)!,
      currentSoft: Color.lerp(currentSoft, other.currentSoft, t)!,
      onCurrent: Color.lerp(onCurrent, other.onCurrent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
    );
  }
}

/// Ombres de la charte, par thème.
@immutable
class ElecPayShadows extends ThemeExtension<ElecPayShadows> {
  const ElecPayShadows({required this.card, required this.float, required this.volt});
  static const dark = ElecPayShadows(
    card: [BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x59000000))],
    float: [BoxShadow(offset: Offset(0, 16), blurRadius: 40, color: Color(0x80000000))],
    volt: [BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x59F5A623))],
  );
  static const light = ElecPayShadows(
    card: [BoxShadow(offset: Offset(0, 6), blurRadius: 20, color: Color(0x140A1628))],
    float: [BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x240A1628))],
    volt: [BoxShadow(offset: Offset(0, 8), blurRadius: 20, color: Color(0x59F5A623))],
  );

  /// Carte posée sur bg.
  final List<BoxShadow> card;

  /// Barre de navigation flottante, feuilles du bas.
  final List<BoxShadow> float;

  /// Halo du bouton Payer central, seul élément qui « brille ».
  final List<BoxShadow> volt;
  @override
  ElecPayShadows copyWith({List<BoxShadow>? card, List<BoxShadow>? float, List<BoxShadow>? volt}) =>
      ElecPayShadows(card: card ?? this.card, float: float ?? this.float, volt: volt ?? this.volt);
  @override
  ElecPayShadows lerp(ElecPayShadows? other, double t) {
    if (other == null) return this;
    return ElecPayShadows(
      card: BoxShadow.lerpList(card, other.card, t)!,
      float: BoxShadow.lerpList(float, other.float, t)!,
      volt: BoxShadow.lerpList(volt, other.volt, t)!,
    );
  }
}

/// Échelle typographique FIXE de la charte (on n’invente pas de taille intermédiaire).
/// Les montants utilisent les chiffres tabulaires.
abstract final class AppText {
  /// Le montant à payer sur le tableau de bord et l'écran de paiement. Chiffres tabulaires.
  static const amountHero = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 36,
    height: 1.1111,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Titre d'écran d'accueil (« Bonjour Loick »).
  static const display = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    height: 1.2857,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.28,
  );

  /// Titre d'écran.
  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    height: 1.3636,
    fontWeight: FontWeight.w600,
  );

  /// Titre de section ou de carte.
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    height: 1.4444,
    fontWeight: FontWeight.w600,
  );

  /// Montant dans une liste ou une carte.
  static const amount = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    height: 1.4118,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Texte courant.
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    height: 1.4667,
    fontWeight: FontWeight.w400,
  );

  /// Texte courant mis en avant, libellé de bouton.
  static const bodyStrong = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    height: 1.4667,
    fontWeight: FontWeight.w500,
  );

  /// Texte secondaire, dates, sous-titres de ligne.
  static const bodySm = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.5385,
    fontWeight: FontWeight.w400,
  );

  /// Légendes de graphique, unités, mentions (« Estimation »).
  static const caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 1.3333,
    fontWeight: FontWeight.w500,
  );

  /// Petites étiquettes en capitales (sections, badges).
  static const overline = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    height: 1.2727,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.88,
  );

  /// Références de facture, de transaction et de reçu, numéro de compteur.
  static const reference = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 13,
    height: 1.3846,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Espacements (`space-*`).
abstract final class Space {
  /// Écart icône–texte.
  static const double s1 = 4;

  /// Écart dans un groupe serré (badge, puce).
  static const double s2 = 8;

  /// Écart entre lignes d'une carte.
  static const double s3 = 12;

  /// Marge latérale des écrans mobiles et padding de carte.
  static const double s4 = 16;

  /// Padding d'une carte héros.
  static const double s5 = 20;

  /// Écart entre sections d'un écran.
  static const double s6 = 24;

  /// Écart entre blocs majeurs, padding de page du back-office.
  static const double s8 = 32;

  /// Haut de l'écran sous l'en-tête.
  static const double s10 = 40;

  /// Hauteur minimale d'une zone tactile.
  static const double s12 = 48;
}

/// Rayons (`radius-*`).
abstract final class Radii {
  /// Badges, puces, petits champs.
  static const double sm = 8;

  /// Boutons, champs de saisie, lignes cliquables.
  static const double md = 14;

  /// Cartes.
  static const double lg = 20;

  /// Carte héros, feuilles du bas, barre de navigation flottante.
  static const double xl = 28;

  /// Bouton Payer central, avatars, pastilles.
  static const double full = 999;
}

/// Flou du verre (`blur-glass`).
abstract final class Blur {
  /// Flou CSS de la charte, en pixels.
  static const double glass = 24;

  /// Sigma Flutter équivalent (`BackdropFilter`) : la moitié du flou CSS.
  static const double glassSigma = 12;
}
