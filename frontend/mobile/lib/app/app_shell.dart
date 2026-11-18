import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/demo/demo_mode.dart';
import '../core/session/session_expiry_notice.dart';
import '../core/session/session_providers.dart';
import '../core/theme/app_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/tokens.g.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/bottom_sheet.dart';
import '../core/widgets/demo_badge.dart';
import '../core/widgets/state_block.dart';

/// Coquille des écrans principaux (connecté) : le contenu de l'onglet, et la barre du bas flottante
/// par-dessus (le contenu passe dessous, la barre est en verre).
///
/// Si la session EXPIRE ici, la feuille « session expirée » s'affiche (fond opaque : plus rien n'est
/// lisible) ; « Se reconnecter » mène à la connexion.
///
/// F2.5 : les 4 onglets affichent une page d'attente ; F4 → F9 les remplissent, F4 branche l'état
/// hors ligne et la facture la plus urgente (bouton Payer), F6 la feuille de paiement.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  AppTab get _current =>
      AppTab.values.firstWhere((tab) => location.startsWith(tab.path), orElse: () => AppTab.home);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiryNoticeProvider, (previous, due) {
      if (!due) return;
      showSessionExpiredSheet(
        context,
        onReconnect: () {
          Navigator.of(context).pop();
          ref.read(sessionExpiryNoticeProvider.notifier).acknowledge();
        },
      );
    });

    return Scaffold(
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
}

/// Page d'attente d'un onglet (remplacée par le vrai écran à l'étape indiquée). L'onglet Compte
/// porte déjà « Se déconnecter » (le vrai écran Compte arrive en F9).
class PendingTab extends ConsumerWidget {
  const PendingTab({required this.tab, required this.step, super.key});

  final AppTab tab;

  /// Étape du plan qui remplit cet onglet (« F4 »).
  final String step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, 120),
          children: [
            // En-tête comme la maquette de l'accueil : titre, et badge « Mode démo » à droite
            // (affiché tant qu'on ne sait pas : jamais de donnée simulée présentée comme réelle).
            Row(
              children: [
                Expanded(
                  child: Text(tab.label, style: AppText.h1.copyWith(color: c.ink)),
                ),
                if (ref.watch(demoModeProvider).showBadge) const DemoBadge(),
              ],
            ),
            StateBlock.empty(
              icon: tab.icon,
              title: '${tab.label} : bientôt',
              message: 'Cet écran arrive à l’étape $step du plan.',
            ),
            if (tab == AppTab.account)
              AppButton(
                label: 'Se déconnecter',
                icon: AppIcons.signIn,
                variant: ButtonVariant.secondary,
                onPressed: () => ref.read(sessionManagerProvider).logout(),
              ),
          ],
        ),
      ),
    );
  }
}
