import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/state_block.dart';
import '../diagnostic/diagnostic_access.dart';

/// Page d'attente d'un écran de connexion (remplacée en F3.2 → F3.4). En debug et profile, liens
/// vers les pages Diagnostic et Catalogue (pour se connecter et vérifier avant le vrai écran).
class AuthPendingScreen extends StatelessWidget {
  const AuthPendingScreen({required this.title, required this.step, super.key});

  final String title;
  final String step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.s4),
          children: [
            Text(title, style: AppText.h1.copyWith(color: c.ink)),
            StateBlock.empty(
              icon: AppIcons.signIn,
              title: '$title : bientôt',
              message: 'Cet écran arrive à l’étape $step du plan.',
            ),
            if (diagnosticsEnabled) ...[
              TextButton(
                onPressed: () => context.push('/diagnostic'),
                child: Text('Diagnostic', style: AppText.bodyStrong.copyWith(color: c.currentText)),
              ),
              TextButton(
                onPressed: () => context.push('/catalogue'),
                child: Text('Catalogue', style: AppText.bodyStrong.copyWith(color: c.currentText)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
