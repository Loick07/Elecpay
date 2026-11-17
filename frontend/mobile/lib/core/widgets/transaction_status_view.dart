import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format/numbers.dart';
import '../format/phone.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.g.dart';
import 'app_button.dart';
import 'statuses.dart';

/// Phase d'un paiement, vue par l'utilisateur.
enum TransactionPhase {
  /// En attente du code PIN (`en_attente`).
  pending,

  /// Confirmé par le prestataire (`reussie`).
  succeeded,

  /// Refusé (`echouee`), avec un motif.
  failed,

  /// Code PIN pas saisi à temps (`expiree`).
  expired,

  /// Pas de réponse (délai dépassé, état inconnu) : on VÉRIFIE, on ne dit jamais « échoué ».
  unknown;

  /// Depuis le statut de l'API (`null` ou valeur inconnue : vérification en cours).
  static TransactionPhase fromStatus(String? status) => switch (status) {
    'en_attente' => pending,
    'reussie' => succeeded,
    'echouee' => failed,
    'expiree' => expired,
    _ => unknown,
  };

  /// Couleur, icône et mot de la table des statuts.
  StatusStyle get style => switch (this) {
    pending => transactionStatuses['en_attente']!,
    succeeded => transactionStatuses['reussie']!,
    failed => transactionStatuses['echouee']!,
    expired => transactionStatuses['expiree']!,
    unknown => transactionUnknown,
  };
}

/// Écran d'état d'un paiement (maquette de l'écran 9, `frontend/design/components/TransactionStatus`).
/// APPARENCE seulement : l'interrogation de l'API toutes les 3 s et le passage en « Vérification en
/// cours » arrivent en F6. Une seule action utile par état :
/// - en attente : aucune (« Ne relancez pas le paiement ») ;
/// - réussi : Voir le reçu (légère vibration, coche qui apparaît en 250 ms) ;
/// - échoué / expiré : motif précis + Réessayer ;
/// - vérification en cours : interdiction EXPLICITE de repayer, aucun bouton de paiement.
class TransactionStatusView extends StatefulWidget {
  const TransactionStatusView({
    required this.phase,
    required this.amount,
    required this.operatorLabel,
    required this.phone,
    required this.reference,
    this.failureReason,
    this.onViewReceipt,
    this.onRetry,
    this.onHome,
    super.key,
  }) : assert(
         phase != TransactionPhase.unknown || onHome != null,
         'Vérification en cours : une sortie qui ne paie rien (onHome) est obligatoire',
       );

  final TransactionPhase phase;
  final int amount;

  /// « MTN MoMo ».
  final String operatorLabel;

  /// Numéro débité (« +242061234567 »).
  final String phone;

  /// Référence de la transaction (« TX-2026-004812 »), toujours affichée.
  final String reference;

  /// Motif d'échec donné par l'API (« solde Mobile Money insuffisant… »).
  final String? failureReason;
  final VoidCallback? onViewReceipt;
  final VoidCallback? onRetry;
  final VoidCallback? onHome;

  @override
  State<TransactionStatusView> createState() => _TransactionStatusViewState();
}

class _TransactionStatusViewState extends State<TransactionStatusView> {
  @override
  void initState() {
    super.initState();
    if (widget.phase == TransactionPhase.succeeded) HapticFeedback.lightImpact();
  }

  @override
  void didUpdateWidget(TransactionStatusView old) {
    super.didUpdateWidget(old);
    if (widget.phase == TransactionPhase.succeeded && old.phase != TransactionPhase.succeeded) {
      HapticFeedback.lightImpact();
    }
  }

  ({String title, String message}) get _texts {
    final amount = formatFcfa(widget.amount);
    return switch (widget.phase) {
      TransactionPhase.pending => (
        title: 'Confirmez sur votre téléphone',
        message:
            'Un message ${widget.operatorLabel} est arrivé sur le ${formatPhone(widget.phone)}. '
            'Saisissez votre code PIN pour valider le paiement de $amount.',
      ),
      TransactionPhase.succeeded => (
        title: 'Paiement réussi',
        message: 'Votre paiement de $amount est confirmé.',
      ),
      TransactionPhase.failed => (
        title: 'Paiement échoué',
        message: widget.failureReason ?? 'Le paiement n’a pas abouti. Vous pouvez réessayer.',
      ),
      TransactionPhase.expired => (
        title: 'Paiement expiré',
        message:
            'Le code PIN n’a pas été saisi à temps : le paiement n’a pas été effectué. '
            'Vous pouvez réessayer.',
      ),
      TransactionPhase.unknown => (
        title: 'Vérification en cours',
        message:
            'Nous vérifions votre paiement. Ne payez pas une deuxième fois : vous serez notifié.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = widget.phase.style;
    final texts = _texts;
    final action = switch (widget.phase) {
      TransactionPhase.succeeded when widget.onViewReceipt != null => AppButton(
        label: 'Voir le reçu',
        onPressed: widget.onViewReceipt,
      ),
      TransactionPhase.failed || TransactionPhase.expired when widget.onRetry != null => AppButton(
        label: 'Réessayer',
        icon: AppIcons.retry,
        onPressed: widget.onRetry,
      ),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _Pastille(phase: widget.phase, style: style),
          ),
          const SizedBox(height: Space.s4),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              texts.title,
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: Space.s3),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                texts.message,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
            ),
          ),
          if (widget.phase == TransactionPhase.pending) ...[
            const SizedBox(height: Space.s5),
            const _Note(
              'Vous pouvez quitter cet écran : vous serez notifié dès la confirmation. '
              'Ne relancez pas le paiement.',
            ),
          ],
          const SizedBox(height: Space.s6),
          Text(
            widget.reference,
            textAlign: TextAlign.center,
            style: AppText.reference.copyWith(color: c.inkMuted, fontSize: 12),
          ),
          if (action != null) ...[const SizedBox(height: Space.s4), action],
          if (widget.onHome != null) ...[
            const SizedBox(height: Space.s2),
            AppButton(
              label: 'Retour à l’accueil',
              variant: ButtonVariant.ghost,
              onPressed: widget.onHome,
            ),
          ],
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.phase, required this.style});

  final TransactionPhase phase;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final circle = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: style.background(c), shape: BoxShape.circle),
      child: AppIcon(style.icon, size: 36, color: style.iconColor(c)),
    );
    if (phase != TransactionPhase.succeeded) return circle;
    // Réussite : la coche apparaît en 250 ms (rien si les animations sont réduites), sans rebond.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Motion.of(context, Motion.appear),
      curve: Motion.curve,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: circle,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: 18, color: c.currentText),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(text, style: AppText.bodySm.copyWith(color: c.inkMuted)),
          ),
        ],
      ),
    );
  }
}
