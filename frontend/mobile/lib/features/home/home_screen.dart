import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/cache/cached_api.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/format/formats.dart';
import '../../core/models/bills.dart';
import '../../core/models/households.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/hero_bill_card.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/statuses.dart';
import 'home_cards.dart';
import 'home_data.dart';
import 'home_rules.dart';

/// Horloge de l'accueil (date de l'en-tête, compte à rebours de l'échéance) : remplacée en test.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Écran 5 : Accueil (maquette `Main.dc.html`). Chaque carte se charge et échoue SÉPARÉMENT
/// (lectures de `home_data.dart`) ; tirer vers le bas relit tout.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Cloche : relue au retour sur l'application et à chaque arrivée sur l'accueil, JAMAIS par
    // interrogation périodique. (Première arrivée : la lecture se fait déjà en construisant.)
    _lifecycle = AppLifecycleListener(onResume: _refreshBell);
    if (ref.read(unreadCountProvider).hasValue) unawaited(_refreshBell());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshBell() => ref.read(unreadCountProvider.notifier).refresh();

  /// Tirer vers le bas : toutes les lectures sont refaites (chaque carte à son rythme).
  Future<void> _refreshAll() async {
    ref
      ..invalidate(homeUserProvider)
      ..invalidate(householdsProvider)
      ..invalidate(toPayBillsProvider)
      ..invalidate(householdMetersProvider)
      ..invalidate(monthConsumptionProvider)
      ..invalidate(recentActivityProvider);
    unawaited(ref.read(demoModeProvider.notifier).refresh());
    Future<void> quietly(Future<Object?> f) => f.then((_) {}, onError: (Object _) {});
    await Future.wait([
      quietly(ref.read(urgentBillProvider.future)),
      quietly(ref.read(monthConsumptionProvider.future)),
      quietly(ref.read(recentActivityProvider.future)),
      quietly(_refreshBell()),
    ]);
  }

  void _retryAll() => unawaited(_refreshAll());

  void _open(String screen, String step) => context.push(Routes.pending(screen, step));

  Future<void> _chooseHousehold(List<HouseholdSummary> households, int? shownId) async {
    final chosen = await showAppSheet<int>(
      context,
      child: HouseholdChoiceList(households: households, shownId: shownId),
    );
    if (chosen != null) await ref.read(savedHouseholdProvider.notifier).choose(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(homeClockProvider)();
    final user = ref.watch(homeUserProvider);
    final households = ref.watch(householdsProvider);
    final toPay = ref.watch(toPayBillsProvider);
    final shownId = ref.watch(shownHouseholdIdProvider).value;
    final urgent = ref.watch(urgentBillProvider);
    final month = ref.watch(monthConsumptionProvider);
    final activity = ref.watch(recentActivityProvider);
    final unread = ref.watch(unreadCountProvider).value;

    // Plus rien de lisible (ni compte, ni foyers, ni factures, même en cache) : un seul bloc.
    if (user.hasError && households.hasError && toPay.hasError) {
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                if (toPay.error case final ApiFailure failure)
                  stateForFailure(failure, what: 'votre accueil', onRetry: _retryAll)
                else
                  StateBlock.error(what: 'votre accueil', onRetry: _retryAll),
              ],
            ),
          ),
        ),
      );
    }

    final offline = _oldestCached([
      user.value,
      households.value,
      toPay.value,
      month.value?.summary,
      activity.value?.offline,
    ]);
    final householdList = households.value?.data ?? const <HouseholdSummary>[];
    final noMeter = month.hasValue && month.value == null;
    final nothingToPay = urgent.hasValue && urgent.value!.urgent == null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            key: const Key('home.list'),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s5, Space.s4, 120),
            children: [
              HomeHeader(
                date: formatWeekdayDate(now),
                firstName: user.value == null ? null : greetingName(user.value!.data.fullName),
                unread: unread,
                showDemoBadge: ref.watch(demoModeProvider).showBadge,
                onNotifications: () => _open('Notifications', 'F4.3'),
              ),
              if (offline != null) ...[
                const SizedBox(height: Space.s3),
                OfflineBanner(offline.label),
              ],
              if (householdList.isNotEmpty) ...[
                const SizedBox(height: Space.s3),
                HouseholdSelector(
                  households: householdList,
                  shownId: shownId,
                  onTap: householdList.length > 1
                      ? () => _chooseHousehold(householdList, shownId)
                      : null,
                ),
              ],
              const SizedBox(height: Space.s4),
              // Compte neuf (aucun compteur, rien à payer) : une seule invitation, pas de
              // « Tout est payé » trompeur.
              if (noMeter && nothingToPay)
                StateBlock.empty(
                  key: const Key('home.noMeter'),
                  icon: AppIcons.meter,
                  title: 'Ajoutez votre premier compteur',
                  message:
                      'Avec votre N° de branchement et votre N° client E²C, ElecPay affiche '
                      'votre consommation et vos factures.',
                  actionLabel: 'Ajouter un compteur',
                  onAction: () => _open('Compteurs et foyers', 'F8'),
                )
              else ...[
                _urgentSection(urgent, householdList.length),
                const SizedBox(height: Space.s4),
                if (!noMeter) _monthSection(month),
              ],
              const SizedBox(height: Space.s6),
              _activitySection(activity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _urgentSection(AsyncValue<UrgentBillCard> urgent, int householdCount) {
    return switch (urgent) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.urgent case final bill?)
            _hero(bill, value, householdCount)
          else
            const AllPaidCard(),
          for (final o in value.elsewhere) ...[
            const SizedBox(height: Space.s2),
            OverdueElsewhereRow(
              overdue: o,
              onTap: () => ref.read(savedHouseholdProvider.notifier).choose(o.householdId),
            ),
          ],
        ],
      ),
      AsyncError(:final error) => CardFailure(
        error: error,
        what: 'vos factures',
        onRetry: () => ref.invalidate(toPayBillsProvider),
      ),
      _ => AppSkeleton(loading: true, child: _sampleHero()),
    };
  }

  Widget _hero(BillSummary bill, UrgentBillCard card, int householdCount) {
    final now = ref.read(homeClockProvider)();
    return HeroBillCard(
      key: const Key('home.hero'),
      periodLabel: formatBillPeriodShort(bill.periodStart, bill.periodEnd),
      status: billStatus(bill.status),
      amount: bill.amountTotal,
      dueDate: bill.dueDate,
      now: now,
      meterLabel: bill.meterLabel == null
          ? bill.meterReference
          : '${bill.meterLabel} · ${bill.meterReference}',
      consumptionKwh: bill.consumptionKwh,
      householdName: householdCount > 1 ? bill.householdName : null,
      online: card.bills is FreshData,
      payment: switch (card.action) {
        UrgentBillAction.paymentInProgress => HeroPayment.inProgress,
        UrgentBillAction.none || null => HeroPayment.none,
        UrgentBillAction.pay => HeroPayment.pay,
      },
      onDetail: () => _open('Détail de la facture', 'F5'),
      onPay: () => _open('Paiement', 'F6'),
      onOpenPayment: () => _open('Suivi du paiement', 'F6'),
    );
  }

  Widget _sampleHero() => HeroBillCard(
    periodLabel: 'sept.–oct. 2026',
    status: billStatus(BillStatuses.unpaid),
    amount: 31420,
    dueDate: DateTime.utc(2026, 11, 18),
    now: DateTime.utc(2026, 11, 12),
    meterLabel: '0412-8833',
    consumptionKwh: 417.4,
    online: true,
    onDetail: () {},
    onPay: () {},
  );

  Widget _monthSection(AsyncValue<MonthConsumption?> month) => switch (month) {
    AsyncData(value: final m?) => MonthCard(
      overline: [
        formatMonthSoFar(m.summary.data.thisMonth.start, m.summary.data.thisMonth.end),
        if (m.meterCount > 1 && m.meter != null) m.meter!.label ?? m.meter!.reference,
      ].join(' · '),
      kwh: m.summary.data.thisMonth.consumptionKwh,
      estimate: switch (m.summary.data.monthEndEstimate) {
        final e? => [
          'Estimation fin de mois : ${formatApproxKwh(e.consumptionKwh)}',
          if (e.energyCost case final cost?) formatApproxFcfa(cost),
        ].join(' · '),
        null => null,
      },
      bars: [
        for (final (i, p) in m.days.data.points.indexed)
          (
            kwh: p.consumptionKwh,
            dashed: p.isEstimated || i == m.days.data.points.length - 1,
          ),
      ],
      onTap: () => context.go(AppTab.consumption.path),
    ),
    AsyncData() => const SizedBox.shrink(),
    AsyncError(:final error) => CardFailure(
      error: error,
      what: 'votre consommation',
      onRetry: () => ref
        ..invalidate(householdMetersProvider)
        ..invalidate(monthConsumptionProvider),
    ),
    _ => AppSkeleton(
      loading: true,
      child: MonthCard(
        overline: 'Novembre, du 1er au 12',
        kwh: 82.6,
        estimate: 'Estimation fin de mois : ≈ 206 kWh',
        bars: [for (var i = 0; i < homeChartDays; i++) (kwh: 5.0 + i % 4, dashed: false)],
        onTap: () {},
      ),
    ),
  };

  Widget _activitySection(AsyncValue<RecentActivity> activity) => switch (activity) {
    AsyncData(:final value) => ActivityCard(
      lines: activityLines(value.items),
      onSeeAll: () => _open('Historique des paiements', 'F6'),
    ),
    AsyncError(:final error) => CardFailure(
      error: error,
      what: 'votre activité récente',
      onRetry: () => ref.invalidate(recentActivityProvider),
    ),
    _ => AppSkeleton(
      loading: true,
      child: ActivityCard(
        lines: const [
          (payment: true, title: 'Facture payée', subtitle: 'MTN MoMo · 10 sept.', amount: 31281),
          (
            payment: false,
            title: 'Nouvelle facture',
            subtitle: 'Maison Mpita · 3 nov.',
            amount: 31420,
          ),
        ],
        onSeeAll: () {},
      ),
    ),
  };
}

/// La plus ancienne des données lues dans le cache (bannière « Hors connexion… »), ou `null`.
CachedData<Object?>? _oldestCached(List<Fetched<Object?>?> fetched) {
  final cached = fetched.whereType<CachedData<Object?>>().toList()
    ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
  return cached.firstOrNull;
}
