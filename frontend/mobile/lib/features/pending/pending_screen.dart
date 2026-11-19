import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/widgets/state_block.dart';

/// Écran poussé qui n'existe pas encore (lien de l'accueil vers une étape suivante du plan) : bouton
/// retour en haut, et « Détail de la facture : bientôt ». Remplacé par le vrai écran à son étape.
class PendingScreen extends StatelessWidget {
  const PendingScreen({required this.screen, required this.step, super.key});

  /// Nom de l'écran (« Détail de la facture »).
  final String screen;

  /// Étape du plan qui l'apporte (« F5 »).
  final String step;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(screen)),
    body: SafeArea(
      child: ListView(
        children: [
          StateBlock.empty(
            icon: AppIcons.hourglass,
            title: '$screen : bientôt',
            message: 'Cet écran arrive à l’étape $step du plan.',
          ),
        ],
      ),
    ),
  );
}
