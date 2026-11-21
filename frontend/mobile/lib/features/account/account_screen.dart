import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/cache/cached_api.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/account.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../auth/models/auth_models.dart';
import '../diagnostic/diagnostic_access.dart';
import '../home/home_data.dart';
import '../households/households_rules.dart' show initials;
import 'account_data.dart';
import 'preferences_data.dart';

/// Écran 14 : Compte (maquette `Profil.dc.html`). En-tête du profil (Modifier), « Mon compte »,
/// réglages, assistance, déconnexion, version.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final user = ref.watch(homeUserProvider).value;
    final households = ref.watch(householdsProvider).value?.data;
    final demo = ref.watch(demoModeProvider).showBadge;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(homeUserProvider)
              ..invalidate(householdsProvider);
          },
          child: ListView(
            key: const Key('account.list'),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s5, Space.s4, 120),
            children: [
              if (ref.watch(homeUserProvider).value case final CachedData<UserPublic> cached) ...[
                OfflineBanner(cached.label),
                const SizedBox(height: Space.s3),
              ],
              if (demo) ...[
                const Align(alignment: Alignment.centerRight, child: DemoBadge()),
                const SizedBox(height: Space.s2),
              ],
              _Header(
                name: user?.data.fullName,
                phone: user == null ? null : formatPhone(user.data.phone),
                onEdit: () => context.push(Routes.profile),
              ),
              // F10.1 : compte illisible (et rien en cache) : on le dit, avec « Réessayer ».
              if (ref.watch(homeUserProvider) case AsyncError(:final error) when user == null) ...[
                const SizedBox(height: Space.s3),
                AccountGroup(
                  rows: [
                    AccountRow(
                      key: const Key('account.user.retry'),
                      icon: AppIcons.retry,
                      label: error is NoConnection
                          ? 'Hors connexion : profil non chargé. Réessayer'
                          : 'Profil illisible : réessayer',
                      onTap: () => ref.invalidate(homeUserProvider),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              AccountGroup(
                title: 'Mon compte',
                rows: [
                  AccountRow(
                    key: const Key('account.households'),
                    icon: AppIcons.household,
                    label: 'Compteurs et foyers',
                    trailing: switch (households?.length) {
                      null => null,
                      1 => '1 foyer',
                      final n => '$n foyers',
                    },
                    onTap: () => context.push(Routes.households),
                  ),
                  AccountRow(
                    key: const Key('account.history'),
                    icon: AppIcons.bill,
                    label: 'Paiements et reçus',
                    onTap: () => context.push(Routes.history),
                  ),
                  AccountRow(
                    key: const Key('account.security'),
                    icon: AppIcons.locked,
                    label: 'Mot de passe et sécurité',
                    onTap: () => context.push(Routes.security),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _AlertsGroup(),
              const SizedBox(height: 14),
              const _DisplayGroup(),
              const SizedBox(height: 14),
              AccountGroup(
                rows: [
                  AccountRow(
                    key: const Key('account.support'),
                    icon: AppIcons.question,
                    label: 'Assistance',
                    onTap: () => context.push(Routes.support),
                  ),
                  AccountRow(
                    key: const Key('account.logout'),
                    icon: AppIcons.signOut,
                    label: 'Se déconnecter',
                    danger: true,
                    onTap: () => unawaited(ref.read(sessionManagerProvider).logout()),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                ['ElecPay $appVersion', if (demo) 'Mode démo'].join(' · '),
                key: const Key('account.version'),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: c.inkFaint),
              ),
              // Debug et profile : pages Diagnostic et Catalogue (jalons sur le téléphone).
              // Constante : retiré de l'APK release par le compilateur.
              if (diagnosticsEnabled)
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (final (label, path) in [
                      ('Diagnostic', '/diagnostic'),
                      ('Catalogue', '/catalogue'),
                    ])
                      TextButton(
                        onPressed: () => context.push(path),
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        child: Text(label, style: AppText.bodySm.copyWith(color: c.currentText)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « LM · Loick Makosso · +242 06 123 45 67 · Modifier ».
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.phone, required this.onEdit});

  /// `null` : compte pas encore lu.
  final String? name;
  final String? phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: 14,
      runSpacing: Space.s2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.currentSoft, shape: BoxShape.circle),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name == null ? '' : initials(name!),
                    style: AppText.h2.copyWith(color: c.currentText, fontSize: 19),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      name ?? 'Mon compte',
                      key: const Key('account.name'),
                      style: AppText.h2.copyWith(color: c.ink),
                    ),
                  ),
                  if (phone != null)
                    Text(phone!, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
          ],
        ),
        Semantics(
          button: true,
          label: 'Modifier mon profil',
          excludeSemantics: true,
          child: Material(
            color: c.surface1,
            shape: StadiumBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              key: const Key('account.edit'),
              customBorder: const StadiumBorder(),
              onTap: onEdit,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Modifier',
                      style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Groupe de lignes (« MON COMPTE », « ME PRÉVENIR »…) dans une carte.
class AccountGroup extends StatelessWidget {
  const AccountGroup({required this.rows, this.title, super.key});

  final String? title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final t?) ...[
          Semantics(
            header: true,
            child: Text(t.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
          ),
          const SizedBox(height: 6),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (i, row) in rows.indexed)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                      ),
                      child: row,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne d'un groupe : icône, libellé, valeur à droite (« 2 foyers »), chevron.
class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  /// « Se déconnecter » : rouge, sans chevron.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = danger ? c.errorText : c.ink;
    final large = MediaQuery.textScalerOf(context).scale(10) > 14;
    return Semantics(
      button: true,
      label: [label, ?trailing].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
            child: Row(
              children: [
                AppIcon(icon, color: danger ? c.errorText : c.inkMuted),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.body.copyWith(
                          color: ink,
                          fontWeight: danger ? FontWeight.w500 : null,
                        ),
                      ),
                      // Texte très agrandi : la valeur passe sous le libellé (sinon « Compte / urs »).
                      if (trailing case final t? when large)
                        Text(t, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
                if (trailing case final t? when !large) ...[
                  const SizedBox(width: Space.s2),
                  Text(t, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                ],
                if (!danger) ...[
                  const SizedBox(width: Space.s2),
                  AppIcon(AppIcons.next, size: 16, color: c.inkFaint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « ME PRÉVENIR » : interrupteurs appliqués par le serveur. Hors connexion (préférences du
/// cache) : affichés, mais pas modifiables.
class _AlertsGroup extends ConsumerWidget {
  const _AlertsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefs = ref.watch(notificationPreferencesProvider);
    final value = prefs.value;
    final offline = value is CachedData<NotificationPreferences>;
    Future<void> set(PreferenceSwitch which, bool on) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(notificationPreferencesProvider.notifier).set(which, on);
      } on ApiFailure catch (failure) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }

    return AccountGroup(
      title: 'Me prévenir',
      rows: switch (prefs) {
        AsyncValue(value: final fetched?) => [
          for (final which in PreferenceSwitch.values)
            SwitchRow(
              key: Key('account.pref.${which.name}'),
              label: which.label,
              detail: which.detail,
              value: which.valueIn(fetched.data),
              onChanged: offline ? null : (on) => set(which, on),
            ),
          if (offline)
            Padding(
              padding: const EdgeInsets.all(Space.s4),
              child: Text(
                'Hors connexion : réglages modifiables une fois reconnecté.',
                style: AppText.caption.copyWith(color: c.inkMuted),
              ),
            ),
        ],
        AsyncError() => [
          AccountRow(
            key: const Key('account.pref.retry'),
            icon: AppIcons.retry,
            label: 'Réglages des alertes illisibles : réessayer',
            onTap: () => ref.invalidate(notificationPreferencesProvider),
          ),
        ],
        _ => [
          const Padding(
            padding: EdgeInsets.all(Space.s4),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      },
    );
  }
}

/// « AFFICHAGE » : thème Nuit / Jour / Auto (D9.2 : Nuit par défaut) et « Effet verre » (désactivé
/// par défaut). Gardés sur l'appareil (D9.1).
class _DisplayGroup extends ConsumerWidget {
  const _DisplayGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(appSettingsProvider);
    return AccountGroup(
      title: 'Affichage',
      rows: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.s3,
            runSpacing: Space.s2,
            children: [
              Text('Thème', style: AppText.body.copyWith(color: c.ink)),
              Semantics(
                container: true,
                label: 'Thème',
                child: Container(
                  padding: const EdgeInsets.all(Space.s1),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  // Wrap : texte très agrandi, les choix passent à la ligne au lieu de déborder.
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      for (final theme in ThemeChoice.values)
                        _ThemeOption(
                          key: Key('account.theme.${theme.name}'),
                          label: theme.label,
                          selected: settings.theme == theme,
                          onTap: () =>
                              unawaited(ref.read(appSettingsProvider.notifier).setTheme(theme)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SwitchRow(
          key: const Key('account.glass'),
          label: 'Effet verre',
          detail:
              'Flou de la barre du bas et des feuilles. Plus joli, mais plus lent sur les '
              'petits téléphones.',
          value: settings.glass,
          onChanged: (on) => ref.read(appSettingsProvider.notifier).setGlass(on),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.label, required this.selected, required this.onTap, super.key});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.surface1 : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(9)),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.bodySm.copyWith(
                    color: selected ? c.ink : c.inkMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne avec un interrupteur (maquette : libellé, sous-titre, interrupteur jaune). TalkBack lit
/// le libellé, le sous-titre et l'état (activé / désactivé). `onChanged` `null` : grisé.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final large = MediaQuery.textScalerOf(context).scale(10) > 14;
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(color: c.ink)),
        Text(detail, style: AppText.caption.copyWith(color: c.inkMuted)),
      ],
    );
    final toggle = Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.onVolt,
      activeTrackColor: c.volt,
      inactiveThumbColor: c.inkMuted,
      inactiveTrackColor: c.surface3,
    );
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
            // Texte très agrandi : l'interrupteur passe sous le libellé (sinon « Consommatio / n »).
            child: large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      texts,
                      const SizedBox(height: Space.s1),
                      Align(alignment: Alignment.centerRight, child: toggle),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: texts),
                      const SizedBox(width: Space.s3),
                      toggle,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
