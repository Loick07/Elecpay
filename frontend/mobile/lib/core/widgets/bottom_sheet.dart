import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.g.dart';
import 'app_button.dart';
import 'glass.dart';

/// Feuille du bas de la charte : verre (un des deux usages permis), coins `radius-xl` en haut,
/// ombre `shadow-float`, poignée. Sert à la feuille de paiement (F2.4, F6), aux filtres, à la
/// session expirée.
class AppSheet extends StatelessWidget {
  const AppSheet({required this.child, this.showHandle = true, super.key});

  final Widget child;

  /// Poignée de glissement (absente si la feuille ne se ferme pas d'un geste).
  final bool showHandle;

  static const _radius = BorderRadius.vertical(top: Radius.circular(Radii.xl));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassSurface(
      borderRadius: _radius,
      shadows: context.shadows.float,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s6, Space.s3, Space.s6, Space.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Space.s4),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: const BorderRadius.all(Radius.circular(Radii.full)),
                    ),
                  ),
                )
              else
                const SizedBox(height: Space.s4),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre une feuille du bas. `dismissible: false` : elle ne se ferme ni d'un geste, ni en touchant
/// à côté, ni par le bouton retour (ex. session expirée : seule issue, se reconnecter).
///
/// `hideContent: true` : derrière la feuille, un fond OPAQUE (couleur `bg`) au lieu du voile
/// habituel. Rien de l'écran du dessous ne reste lisible, même à travers le verre (ex. session
/// expirée : les données du cache ne doivent plus être visibles).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  bool dismissible = true,
  bool hideContent = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  backgroundColor: Colors.transparent,
  barrierColor: hideContent ? context.colors.bg : null,
  elevation: 0,
  sheetAnimationStyle: AnimationStyle(
    duration: Motion.of(context, Motion.appear),
    reverseDuration: Motion.of(context, Motion.press),
  ),
  builder: (context) {
    final sheet = PopScope(
      canPop: dismissible,
      child: AppSheet(showHandle: dismissible, child: child),
    );
    // Masquer aussi pour le lecteur d'écran : rien de ce qui est sous la feuille n'est lu.
    return hideContent ? BlockSemantics(child: sheet) : sheet;
  },
);

/// Feuille « session expirée » (charte, table « États d'écran ») : texte de la charte, une seule
/// action, se reconnecter. Elle ne se ferme pas autrement, et l'écran du dessous est entièrement
/// masqué (la session est finie : ses données ne doivent plus être lisibles).
Future<void> showSessionExpiredSheet(BuildContext context, {required VoidCallback onReconnect}) =>
    showAppSheet<void>(
      context,
      dismissible: false,
      hideContent: true,
      child: SessionExpiredContent(onReconnect: onReconnect),
    );

class SessionExpiredContent extends StatelessWidget {
  const SessionExpiredContent({required this.onReconnect, super.key});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.currentSoft, shape: BoxShape.circle),
            child: AppIcon(AppIcons.signIn, size: 30, color: c.current),
          ),
        ),
        const SizedBox(height: Space.s4),
        Semantics(
          header: true,
          child: Text(
            'Session expirée',
            textAlign: TextAlign.center,
            style: AppText.h2.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: Space.s3),
        Text(
          'Votre session a expiré. Reconnectez-vous pour continuer.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: Space.s6),
        AppButton(label: 'Se reconnecter', icon: AppIcons.signIn, onPressed: onReconnect),
      ],
    );
  }
}
