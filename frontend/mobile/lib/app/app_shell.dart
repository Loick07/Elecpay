import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_expiry_notice.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/bottom_sheet.dart';
import '../features/home/home_data.dart';
import '../features/payments/payment_entry.dart';

/// Coquille des écrans principaux (connecté) : le contenu de l'onglet, et la barre du bas flottante
/// par-dessus (le contenu passe dessous, la barre est en verre).
///
/// Si la session EXPIRE ici, la feuille « session expirée » s'affiche (fond opaque : plus rien n'est
/// lisible) ; « Se reconnecter » mène à la connexion.
///
/// F4 → F9 ont rempli les 4 onglets ; F4 branche l'état hors ligne et la facture la plus urgente
/// (bouton Payer), F6 la feuille de paiement.
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
        // Point rouge sur Factures : au moins une facture en retard (reste à payer, tous foyers).
        billsOverdue: (ref.watch(toPayBillsProvider).value?.data.outstanding.overdueCount ?? 0) > 0,
        onPay: () => payFromBottomBar(context, ref),
      ),
    );
  }
}
