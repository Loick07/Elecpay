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
///
/// Proportions (revues pendant M1, sur une capture de l'itel) : barre de hauteur fixe
/// [barHeight] ; les 5 libellés sur la MÊME ligne (« Payer » a son emplacement dans la rangée,
/// comme les onglets) ; disque placé par la mise en page (jamais par un simple décalage
/// d'affichage), qui dépasse franchement du bord ; fondu vers la couleur du fond derrière la barre,
/// pour que le contenu ne se voie plus entre la barre et le bas de l'écran.
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

  /// Hauteur de la barre (le disque Payer dépasse au-dessus).
  static const barHeight = 64.0;

  /// Disque Payer : diamètre, et dépassement au-dessus du bord haut de la barre.
  static const payDiscSize = 56.0;
  static const payDiscLift = 30.0;

  /// Anneau couleur du fond autour du disque : il le détache du bord de la barre.
  static const payRing = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxTextScale,
      child: Stack(
        children: [
          // Fondu vers le fond : le contenu qui défile s'efface derrière la barre.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const Key('bottomNav.fade'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.bg.withValues(alpha: 0), c.bg.withValues(alpha: 0.9), c.bg],
                    stops: const [0.3, 0.7, 1],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Space.s3,
              0,
              Space.s3,
              Space.s3 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Semantics(
              container: true,
              label: 'Navigation principale',
              child: SizedBox(
                height: payDiscLift + barHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: barHeight,
                      child: GlassSurface(
                        borderRadius: const BorderRadius.all(Radius.circular(Radii.xl)),
                        shadows: context.shadows.float,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.s2),
                          child: Row(
                            children: [
                              _tab(AppTab.home),
                              _tab(AppTab.bills, alert: billsOverdue),
                              Expanded(
                                child: _PayLabel(online: online, onTap: () => _pay(context)),
                              ),
                              _tab(AppTab.consumption),
                              _tab(AppTab.account),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -payRing,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _PayDisc(online: online, onTap: () => _pay(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pay(BuildContext context) {
    if (online) {
      onPay();
      return;
    }
    // Hors ligne : rien ne part ; on dit pourquoi.
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(PayButton.offlineHint)));
  }

  Widget _tab(AppTab tab, {bool alert = false}) => Expanded(
    child: _TabEntry(tab: tab, selected: tab == current, alert: alert, onTap: () => onTab(tab)),
  );
}

/// Gabarit commun des 5 entrées : emplacement d'icône (24), libellé, point de l'onglet actif.
/// Même gabarit partout : les libellés tombent sur la même ligne.
class _EntryLayout extends StatelessWidget {
  const _EntryLayout({required this.icon, required this.label, required this.dot});

  final Widget icon;
  final Widget label;
  final Color dot;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: IconSizes.navigation,
        child: Center(child: icon),
      ),
      const SizedBox(height: 3),
      label,
      const SizedBox(height: 3),
      Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
    ],
  );
}

TextStyle _labelStyle(Color color, {required bool strong}) => AppText.overline.copyWith(
  color: color,
  letterSpacing: 0,
  fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
);

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
          child: Center(
            child: _EntryLayout(
              icon: Stack(
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
              label: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle(color, strong: selected),
              ),
              dot: selected ? c.volt : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Emplacement de « Payer » dans la rangée : libellé sur la ligne des autres ; l'icône est portée
/// par le disque, au-dessus. Lu une seule fois par TalkBack (sur le disque).
class _PayLabel extends StatelessWidget {
  const _PayLabel({required this.online, required this.onTap});

  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Opacity(
        opacity: online ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: _EntryLayout(
              icon: const SizedBox.shrink(),
              label: Text('Payer', maxLines: 1, style: _labelStyle(c.voltText, strong: true)),
              dot: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayDisc extends StatelessWidget {
  const _PayDisc({required this.online, required this.onTap});

  final bool online;
  final VoidCallback onTap;

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
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppBottomNav.payRing),
            decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
            child: Container(
              width: AppBottomNav.payDiscSize,
              height: AppBottomNav.payDiscSize,
              decoration: BoxDecoration(
                color: c.volt,
                shape: BoxShape.circle,
                boxShadow: context.shadows.volt,
              ),
              child: AppIcon(AppIcons.navPay, size: 26, color: c.onVolt),
            ),
          ),
        ),
      ),
    );
  }
}
