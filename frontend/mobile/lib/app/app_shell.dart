import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/tokens.g.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/state_block.dart';

/// Coquille des écrans principaux : le contenu de l'onglet, et la barre du bas flottante par-dessus
/// (le contenu passe dessous, la barre est en verre).
///
/// F2.5 : les 4 onglets affichent une page d'attente ; F4 → F9 les remplissent, F4 branche l'état
/// hors ligne et la facture la plus urgente (bouton Payer), F6 la feuille de paiement.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  AppTab get _current =>
      AppTab.values.firstWhere((tab) => location.startsWith(tab.path), orElse: () => AppTab.home);

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: child,
    bottomNavigationBar: AppBottomNav(
      current: _current,
      onTab: (tab) => context.go(tab.path),
      online: true,
      onPay: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Le paiement arrive à l’étape F6.'))),
    ),
  );
}

/// Page d'attente d'un onglet (remplacée par le vrai écran à l'étape indiquée).
class PendingTab extends StatelessWidget {
  const PendingTab({required this.tab, required this.step, super.key});

  final AppTab tab;

  /// Étape du plan qui remplit cet onglet (« F4 »).
  final String step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, 0),
              child: Text(tab.label, style: AppText.h1.copyWith(color: c.ink)),
            ),
            Expanded(
              child: StateBlock.empty(
                icon: tab.icon,
                title: '${tab.label} : bientôt',
                message: 'Cet écran arrive à l’étape $step du plan.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
