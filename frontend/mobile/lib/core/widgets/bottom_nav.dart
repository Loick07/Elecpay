import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'glass.dart';
import 'pay_button.dart';

/// Les 4 onglets de la barre du bas (Payer, au centre, n'est pas un onglet : il ouvre la feuille
/// de paiement de la facture la plus urgente).
enum AppTab {
  home('Accueil', AppIcons.navHome, '/accueil'),
  bills('Factures', AppIcons.navBills, '/factures'),
  consumption('Conso', AppIcons.navConsumption, '/conso'),
  account('Compte', AppIcons.navAccount, '/compte');

  const AppTab(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

/// Barre de navigation flottante de la charte (`frontend/design/components/BottomNav`, maquette) :
/// verre (un des deux usages permis), décollée de 12 des bords, 5 entrées, **Payer** au centre en
/// disque `volt` de 56 surélevé.
///
/// - onglet actif : icône et libellé `ink`, point `volt` dessous ; inactifs : `ink-muted` ;
/// - pastille `error` sur Factures quand une facture est en retard ;
/// - HORS LIGNE : Payer est désactivé (aucun paiement ne part) ; le toucher explique pourquoi
///   (« Connexion nécessaire pour payer »).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.current,
    required this.onTab,
    required this.onPay,
    required this.online,
    this.billsOverdue = false,
    super.key,
  });

  final AppTab current;
  final ValueChanged<AppTab> onTab;
  final VoidCallback onPay;
  final bool online;
  final bool billsOverdue;

  /// Les libellés de la barre grandissent avec le réglage du téléphone, jusqu'à 130 % (au-delà,
  /// 5 entrées ne tiennent plus sur 360 points ; vu au test à 200 %).
  static const maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Space.s3,
          0,
          Space.s3,
          Space.s3 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Semantics(
          container: true,
          label: 'Navigation principale',
          child: GlassSurface(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.xl)),
            shadows: context.shadows.float,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.s2, Space.s2, Space.s2, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _tab(AppTab.home),
                  _tab(AppTab.bills, alert: billsOverdue),
                  Expanded(
                    child: _PayEntry(online: online, onPay: onPay),
                  ),
                  _tab(AppTab.consumption),
                  _tab(AppTab.account),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(AppTab tab, {bool alert = false}) => Expanded(
    child: _TabEntry(tab: tab, selected: tab == current, alert: alert, onTap: () => onTab(tab)),
  );
}

class _TabEntry extends StatelessWidget {
  const _TabEntry({
    required this.tab,
    required this.selected,
    required this.alert,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final bool alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.ink : c.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: alert ? '${tab.label}, une facture est en retard' : tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppIcon(tab.icon, size: IconSizes.navigation, color: color),
                  if (alert)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: c.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface2, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.overline.copyWith(
                  color: color,
                  letterSpacing: 0,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? c.volt : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayEntry extends StatelessWidget {
  const _PayEntry({required this.online, required this.onPay});

  final bool online;
  final VoidCallback onPay;

  void _tap(BuildContext context) {
    if (online) {
      onPay();
      return;
    }
    // Hors ligne : rien ne part ; on dit pourquoi.
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(PayButton.offlineHint)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: online,
      label: online ? 'Payer' : 'Payer, ${PayButton.offlineHint.toLowerCase()}',
      excludeSemantics: true,
      child: Opacity(
        opacity: online ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, -14),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.volt,
                    shape: BoxShape.circle,
                    boxShadow: context.shadows.volt,
                  ),
                  child: AppIcon(AppIcons.navPay, size: 26, color: c.onVolt),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  'Payer',
                  maxLines: 1,
                  style: AppText.overline.copyWith(color: c.voltText, letterSpacing: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
