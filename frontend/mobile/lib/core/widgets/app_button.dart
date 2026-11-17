import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.g.dart';

/// Variantes de la charte (`frontend/design/components/Button`).
enum ButtonVariant {
  /// Action principale de l'écran (une seule), jaune. Écran d'argent : le montant dans le libellé.
  primary,

  /// Action secondaire (Télécharger le reçu, Partager). Surface opaque : le verre est réservé à
  /// la barre du bas et aux feuilles.
  secondary,

  /// Lien d'action dans une carte (Voir le détail).
  ghost,

  /// Action destructive (ouvre une confirmation avec motif).
  danger,
}

/// Bouton de la charte. Son libellé dit EXACTEMENT ce qui va se passer (« Payer 31 420 FCFA »).
///
/// - `onPressed` à `null` : désactivé (opacité 45 %), seulement quand une condition visible manque.
/// - Chargement : le bouton garde sa place, un indicateur remplace l'icône, le libellé dit ce qui se
///   passe (`loadingLabel`) et il n'est plus cliquable. Si `onPressed` renvoie un `Future`, le
///   chargement est automatique jusqu'à sa fin : un double toucher ne lance JAMAIS deux actions
///   (protection contre le double paiement).
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    super.key,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _running = false;

  bool get _loading => widget.loading || _running;
  bool get _enabled => widget.onPressed != null;

  Future<void> _tap() async {
    if (_loading || !_enabled) return;
    final result = widget.onPressed!();
    if (result is! Future<void>) return;
    setState(() => _running = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, foreground, border) = switch (widget.variant) {
      ButtonVariant.primary => (c.volt, c.onVolt, null),
      ButtonVariant.secondary => (c.surface2, c.ink, c.glassBorder),
      ButtonVariant.ghost => (Colors.transparent, c.voltText, null),
      ButtonVariant.danger => (c.errorSoft, c.errorText, null),
    };
    final label = _loading ? (widget.loadingLabel ?? widget.label) : widget.label;
    final leading = _loading
        ? SizedBox.square(
            dimension: IconSizes.list,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : (widget.icon == null ? null : AppIcon(widget.icon!, color: foreground));

    return Semantics(
      button: true,
      enabled: _enabled && !_loading,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: _enabled ? 1 : 0.45,
        duration: Motion.of(context, Motion.press),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled && !_loading ? _tap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leading != null) ...[leading, const SizedBox(width: Space.s2)],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppText.bodyStrong.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
