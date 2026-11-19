import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Bas d'une liste paginée : demande la page suivante dès qu'il est construit (donc presque
/// visible) ; en cas d'échec, « Impossible de charger la suite. Réessayer ».
class LoadMoreFooter extends StatefulWidget {
  const LoadMoreFooter({required this.onLoad, this.failed = false, super.key});

  final VoidCallback onLoad;

  /// La page suivante a échoué : bouton « Réessayer » (aucune relance automatique).
  final bool failed;

  @override
  State<LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<LoadMoreFooter> {
  @override
  void initState() {
    super.initState();
    if (!widget.failed) WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (widget.failed) {
      return Center(
        child: TextButton(
          key: const Key('loadMore.retry'),
          onPressed: widget.onLoad,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            'Impossible de charger la suite. Réessayer',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: c.currentText),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(Space.s4),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Chargement de la suite',
          ),
        ),
      ),
    );
  }
}
