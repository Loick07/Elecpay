import 'package:flutter/material.dart';

import '../network/api_failure.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'app_button.dart';

/// Couleur de la pastille d'un bloc d'état.
enum StateTone { neutral, success, error, warning }

/// Bloc d'état centré de la charte (`frontend/design/components/StateBlock`, maquette de l'écran 6) :
/// pastille ronde de 64 avec son icône, titre qui nomme la situation, phrase qui dit quoi faire, une
/// action au plus. Textes de référence : table « États d'écran » de la charte.
class StateBlock extends StatelessWidget {
  const StateBlock({
    required this.icon,
    required this.title,
    required this.message,
    this.tone = StateTone.neutral,
    this.actionLabel,
    this.onAction,
    this.actionVariant = ButtonVariant.primary,
    this.reference,
    super.key,
  });

  /// Vide : ce qui manque et comment le remplir ; une action `primary`.
  const StateBlock.empty({
    required String title,
    required String message,
    IconData icon = AppIcons.empty,
    StateTone tone = StateTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) : this(
         icon: icon,
         title: title,
         message: message,
         tone: tone,
         actionLabel: actionLabel,
         onAction: onAction,
         key: key,
       );

  /// Erreur serveur : « Impossible de charger vos factures. Réessayez dans un instant. » ;
  /// « Réessayer » en `secondary` ; la référence de la requête en petit.
  const StateBlock.error({
    required String what,
    required VoidCallback onRetry,
    String? reference,
    Key? key,
  }) : this(
         icon: AppIcons.error,
         title: 'Chargement impossible',
         message: 'Impossible de charger $what. Réessayez dans un instant.',
         tone: StateTone.error,
         actionLabel: 'Réessayer',
         onAction: onRetry,
         actionVariant: ButtonVariant.secondary,
         reference: reference,
         key: key,
       );

  /// Hors connexion et RIEN en cache (sinon : la bannière au-dessus du contenu gardé).
  const StateBlock.offline({required VoidCallback onRetry, Key? key})
    : this(
        icon: AppIcons.offline,
        title: 'Hors connexion',
        message: 'Vérifiez votre connexion internet puis réessayez.',
        tone: StateTone.warning,
        actionLabel: 'Réessayer',
        onAction: onRetry,
        actionVariant: ButtonVariant.secondary,
        key: key,
      );

  /// Accès refusé (403 / 404), sans action. `message` : celui de l'API par défaut (« Facture
  /// introuvable. »…) ; [householdNotShared] seulement sur les écrans qui concernent un foyer.
  const StateBlock.accessDenied({required String message, String? reference, Key? key})
    : this(
        icon: AppIcons.locked,
        title: 'Accès impossible',
        message: message,
        reference: reference,
        key: key,
      );

  final IconData icon;
  final String title;
  final String message;
  final StateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ButtonVariant actionVariant;

  /// Référence de la requête (`X-Request-ID`), affichée en petit : l'équipe retrouve la requête.
  final String? reference;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, foreground) = switch (tone) {
      StateTone.neutral => (c.surface3, c.inkMuted),
      StateTone.success => (c.successSoft, c.success),
      StateTone.error => (c.errorSoft, c.error),
      StateTone.warning => (c.warningSoft, c.warning),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: AppIcon(icon, size: 30, color: foreground),
              ),
              const SizedBox(height: Space.s3),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.h2.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(height: Space.s3),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.s6),
                AppButton(label: actionLabel!, onPressed: onAction, variant: actionVariant),
              ],
              if (reference != null) ...[
                const SizedBox(height: Space.s4),
                Text(
                  'Référence : $reference',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Texte de la charte pour un foyer qui n'est plus accessible. À n'utiliser QUE sur les écrans qui
/// concernent un foyer (foyer, ses compteurs, ses membres) : ailleurs, le message de l'API.
const householdNotShared = 'Ce foyer ne vous est plus partagé.';

/// Le bon bloc d'état pour un échec de lecture SANS donnée en cache (avec cache : la bannière).
///
/// - `what` : ce que l'écran charge, avec son article (« vos factures ») ;
/// - accès refusé (403 / 404) : le message de l'API, sauf si l'écran donne le sien
///   (`accessDeniedMessage: householdNotShared` sur un écran de foyer) ;
/// - `SessionExpired` n'a pas de bloc : c'est la feuille « session expirée » qui s'en charge
///   (`showSessionExpiredSheet`).
StateBlock stateForFailure(
  ApiFailure failure, {
  required String what,
  required VoidCallback onRetry,
  String? accessDeniedMessage,
}) => switch (failure) {
  NoConnection() => StateBlock.offline(onRetry: onRetry),
  ApiRejected(statusCode: 403 || 404) => StateBlock.accessDenied(
    message: accessDeniedMessage ?? failure.message,
    reference: failure.reference,
  ),
  _ => StateBlock.error(what: what, onRetry: onRetry, reference: failure.reference),
};
