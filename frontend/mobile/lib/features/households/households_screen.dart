import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/households.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../home/home_data.dart';
import 'households_data.dart';
import 'households_rules.dart';

/// Écran 15 : Compteurs et foyers (maquette `Compteurs.dc.html`). Invitations reçues en haut, une
/// carte par foyer (compteurs, puissance, membres, mon rôle). Les droits viennent du serveur.
class HouseholdsScreen extends ConsumerWidget {
  const HouseholdsScreen({super.key});

  static Future<void> refresh(WidgetRef ref) async {
    ref
      ..invalidate(householdsProvider)
      ..invalidate(invitationsProvider)
      ..invalidate(toPayBillsProvider)
      ..invalidate(householdDetailProvider);
    try {
      await ref.read(householdsProvider.future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final households = ref.watch(householdsProvider);
    final invitations = ref.watch(invitationsProvider).value ?? const <InvitationPublic>[];
    void retry() => unawaited(refresh(ref));

    final children = <Widget>[
      // Badge dans la page, pas dans la barre : à 200 %, il y écrasait le titre.
      if (ref.watch(demoModeProvider).showBadge) ...[
        const Align(alignment: Alignment.centerRight, child: DemoBadge()),
        const SizedBox(height: Space.s3),
      ],
      for (final invitation in invitations) ...[
        InvitationCard(invitation: invitation),
        const SizedBox(height: Space.s3),
      ],
      if (households.value case final CachedData<List<HouseholdSummary>> cached) ...[
        OfflineBanner(cached.label),
        const SizedBox(height: Space.s3),
      ],
      ...switch (households) {
        AsyncValue(:final value?) when value.data.isEmpty => [
          const StateBlock.empty(
            key: Key('households.empty'),
            icon: AppIcons.household,
            title: 'Aucun foyer',
            message:
                'Ajoutez votre compteur E²C avec votre N° de branchement et votre N° client : '
                'ElecPay crée le foyer avec lui.',
          ),
        ],
        AsyncValue(:final value?) => [
          for (final h in value.data) ...[
            HouseholdCard(summary: h),
            const SizedBox(height: Space.s3),
          ],
          Text(
            'Un payeur délégué voit et paie les factures du foyer. Il ne peut ni le modifier ni '
            'ajouter de compteur.',
            style: AppText.caption.copyWith(color: c.inkFaint),
          ),
        ],
        AsyncError(:final error) => [
          if (error case final ApiFailure failure)
            stateForFailure(failure, what: 'vos foyers', onRetry: retry)
          else
            StateBlock.error(what: 'vos foyers', onRetry: retry),
        ],
        _ => [
          for (var i = 0; i < 2; i++) ...[
            const AppSkeleton(loading: true, child: _CardShell(lines: 3)),
            const SizedBox(height: Space.s3),
          ],
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Compteurs et foyers'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refresh(ref),
          child: ListView(
            key: const Key('households.list'),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s8),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Invitation reçue : « Marie Loemba vous invite comme payeur délégué », foyer, Refuser / Accepter.
class InvitationCard extends ConsumerWidget {
  const InvitationCard({required this.invitation, super.key});

  final InvitationPublic invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        say(done);
      } on ApiFailure catch (failure) {
        say(failure.message);
      }
    }

    final actions = ref.read(householdActionsProvider);
    final household = invitation.household;
    return Container(
      key: Key('households.invitation.${invitation.id}'),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
        border: Border.all(color: c.current),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBox(icon: AppIcons.household, highlight: true),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitationTitle(invitation),
                      style: AppText.bodyStrong.copyWith(color: c.ink),
                    ),
                    Text(
                      '${household.name}, ${household.city}',
                      style: AppText.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              AppButton(
                key: Key('households.decline.${invitation.id}'),
                label: 'Refuser',
                variant: ButtonVariant.secondary,
                onPressed: () => run(() => actions.decline(invitation.id), 'Invitation refusée.'),
              ),
              AppButton(
                key: Key('households.accept.${invitation.id}'),
                label: 'Accepter',
                onPressed: () => run(
                  () => actions.accept(invitation.id),
                  'Vous avez rejoint ${household.name}.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte d'un foyer. Chaque carte lit son foyer et échoue seule (les autres restent affichées).
class HouseholdCard extends ConsumerWidget {
  const HouseholdCard({required this.summary, super.key});

  final HouseholdSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(householdDetailProvider(summary.id));
    final toPay = ref.watch(householdsToPayProvider).value ?? const <int>{};
    return switch (detail) {
      AsyncValue(:final value?) => _FullCard(
        household: value.data,
        toPay: toPay.contains(summary.id),
      ),
      AsyncError() => _CardShell(
        key: Key('households.card.${summary.id}.error'),
        lines: 0,
        title: summary.name,
        subtitle: 'Impossible de charger ce foyer.',
        trailing: AppButton(
          label: 'Réessayer',
          variant: ButtonVariant.ghost,
          onPressed: () => ref.invalidate(householdDetailProvider(summary.id)),
        ),
      ),
      _ => AppSkeleton(
        loading: true,
        child: _CardShell(
          lines: 2,
          title: summary.name,
          subtitle: householdPlaceLine(summary.district, summary.city, summary.myRole),
        ),
      ),
    };
  }
}

class _FullCard extends StatelessWidget {
  const _FullCard({required this.household, required this.toPay});

  final HouseholdDetail household;
  final bool toPay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = household;
    // Texte très agrandi : « À payer » passe sous le lieu (à droite, il coupait les mots).
    final large = MediaQuery.textScalerOf(context).scale(10) > 14;
    final badge = Container(
      key: Key('households.toPay.${h.id}'),
      padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 3),
      decoration: BoxDecoration(
        color: c.currentSoft,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
      ),
      child: Text(
        'À payer',
        style: AppText.caption.copyWith(color: c.currentText, fontWeight: FontWeight.w600),
      ),
    );
    Widget field(String label, String value, {bool mono = false}) => Semantics(
      container: true,
      label: spokenUnits('$label : $value'),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.inkMuted)),
          Text(
            value,
            style: (mono ? AppText.reference : AppText.bodySm).copyWith(
              color: c.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    return Container(
      key: Key('households.card.${h.id}'),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(icon: AppIcons.household, highlight: h.myRole == HouseholdRoles.owner),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          h.name,
                          style: AppText.bodyStrong.copyWith(color: c.ink, fontSize: 16),
                        ),
                      ),
                      Text(
                        householdPlaceLine(h.district, h.city, h.myRole),
                        style: AppText.bodySm.copyWith(color: c.inkMuted),
                      ),
                      if (toPay && large) ...[const SizedBox(height: Space.s1), badge],
                    ],
                  ),
                ),
                if (toPay && !large) ...[const SizedBox(width: Space.s2), badge],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, 14),
            child: h.meters.isEmpty
                ? Text(
                    'Aucun compteur dans ce foyer.',
                    style: AppText.bodySm.copyWith(color: c.inkMuted),
                  )
                : Column(
                    children: [
                      for (final (i, m) in h.meters.indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        Row(
                          key: Key('households.meter.${m.id}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: field(
                                meterCardName(m),
                                formatReference(m.reference),
                                mono: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: field(
                                'Puissance souscrite',
                                subscribedPowerLabel(m.subscribedPowerVa),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                ExcludeSemantics(child: _Avatars(initials: memberInitials(h))),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    membersLine(h),
                    key: Key('households.members.${h.id}'),
                    style: AppText.bodySm.copyWith(color: c.inkMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilles rondes qui se chevauchent (propriétaire, puis membres).
class _Avatars extends StatelessWidget {
  const _Avatars({required this.initials});

  final List<String> initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 28,
      width: 28.0 + (initials.length - 1) * 20,
      child: Stack(
        children: [
          for (final (i, text) in initials.indexed)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == 0 ? c.currentSoft : c.voltSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface1, width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: AppText.caption.copyWith(
                      color: i == 0 ? c.currentText : c.voltText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.highlight});

  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: highlight ? c.currentSoft : c.surface2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      ),
      child: Center(child: AppIcon(icon, color: highlight ? c.currentText : c.inkMuted)),
    );
  }
}

/// Carte simple : chargement (squelette) ou erreur d'un seul foyer.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.lines,
    this.title = 'Maison Mpita',
    this.subtitle = 'Mpita, Pointe-Noire · Propriétaire',
    this.trailing,
    super.key,
  });

  final int lines;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: AppIcons.household, highlight: false),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyStrong.copyWith(color: c.ink)),
                    Text(subtitle, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: Space.s2),
            Text('0412-8833 · 6 kVA', style: AppText.bodySm.copyWith(color: c.inkMuted)),
          ],
        ],
      ),
    );
  }
}
