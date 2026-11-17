import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/cached_api.dart';
import '../../core/format/formats.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bill_row.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hero_bill_card.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/payment_sheet.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/statuses.dart';
import '../../core/widgets/transaction_status_view.dart';
import '../diagnostic/diagnostic_access.dart';

/// Catalogue des composants de la charte (debug et profile seulement, comme la page Diagnostic :
/// retiré du code compilé en release). Données d'exemple de la maquette (Maison Mpita, 31 420 FCFA).
/// À regarder sur l'itel au jalon de F3 : thèmes, hors ligne, chargement, avec et sans flou.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  bool _light = false;
  bool _online = true;
  bool _loading = false;
  AppTab _tab = AppTab.home;
  final _phone = TextEditingController(text: '06 123 45 67');

  static final _now = DateTime.utc(2026, 11, 12, 9);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final theme = _light ? AppTheme.light : AppTheme.dark;
    return Theme(
      data: theme,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final c = context.colors;
    final glass = ref.watch(glassModeProvider);
    final cached = CachedData<int>(
      1,
      savedAt: DateTime.utc(2026, 11, 12, 7, 15),
      failure: const NoConnection(),
      shownAt: _now,
    );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Catalogue')),
      body: Semantics(
        // Marque cherchée dans l'APK par tool/apk_check.dart : absente en release.
        identifier: diagnosticMarker,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, 120),
          children: [
            _Switch('Thème Jour', _light, (v) => setState(() => _light = v)),
            _Switch('En ligne', _online, (v) => setState(() => _online = v)),
            _Switch('Chargement (squelettes)', _loading, (v) => setState(() => _loading = v)),
            _Switch(
              'Effet verre (flou)',
              glass == GlassMode.blur,
              (v) =>
                  ref.read(glassModeProvider.notifier).set(v ? GlassMode.blur : GlassMode.opaque),
            ),
            if (!_online) ...[const SizedBox(height: Space.s3), OfflineBanner.forData(cached)],

            const _Section('Formats'),
            for (final line in [
              formatFcfa(31420),
              formatKwh(417.4),
              formatVariation(-12).text,
              formatVariation(8).text,
              formatCalendarDate(DateTime(2026, 11, 18)),
              formatDateTime(DateTime.utc(2026, 11, 12, 7, 15), now: _now),
              formatBillPeriod(DateTime(2026, 9), DateTime(2026, 10, 31)),
              formatBillPeriodShort(DateTime(2026, 9), DateTime(2026, 10, 31)),
              formatPhone('+242061234567'),
            ])
              Text(line, style: AppText.body.copyWith(color: c.ink)),

            const _Section('Boutons'),
            AppButton(label: 'Payer ${formatFcfa(31420)}', onPressed: () {}),
            const SizedBox(height: Space.s2),
            AppButton(
              label: 'Télécharger le reçu',
              variant: ButtonVariant.secondary,
              icon: AppIcons.bill,
              onPressed: () {},
            ),
            const SizedBox(height: Space.s2),
            AppButton(label: 'Voir le détail', variant: ButtonVariant.ghost, onPressed: () {}),
            const SizedBox(height: Space.s2),
            AppButton(label: 'Annuler la facture', variant: ButtonVariant.danger, onPressed: () {}),
            const SizedBox(height: Space.s2),
            const AppButton(
              label: 'Payer',
              loading: true,
              loadingLabel: 'Envoi de la demande…',
              onPressed: null,
            ),
            const SizedBox(height: Space.s2),
            const AppButton(label: 'Désactivé', onPressed: null),

            const _Section('Champs'),
            PhoneField(controller: _phone),
            const SizedBox(height: Space.s3),
            const AppTextField(
              label: 'Mot de passe',
              password: true,
              helper: '8 caractères minimum',
            ),
            const SizedBox(height: Space.s3),
            const AppTextField(label: 'Nom complet', error: 'Nom trop court'),
            const SizedBox(height: Space.s3),
            const AppTextField(label: 'N° de compteur', mono: true),

            const _Section('Statuts'),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                for (final style in [
                  ...billStatuses.values,
                  ...transactionStatuses.values,
                  transactionUnknown,
                ])
                  StatusBadge(style),
                const DemoBadge(),
              ],
            ),

            const _Section('Factures'),
            AppSkeleton(
              loading: _loading,
              child: HeroBillCard(
                periodLabel: formatBillPeriodShort(DateTime(2026, 9), DateTime(2026, 10, 31)),
                status: billStatus('unpaid'),
                amount: 31420,
                dueDate: DateTime(2026, 11, 18),
                now: _now,
                meterLabel: '0412-8833',
                consumptionKwh: 417.4,
                online: _online,
                householdName: 'Maison Mpita',
                onDetail: () => _snack('Détail de la facture'),
                onPay: () => _openPayment(context),
              ),
            ),
            const SizedBox(height: Space.s4),
            AppSkeleton(
              loading: _loading,
              child: BillRowGroup(
                title: 'Septembre – octobre 2026',
                rows: [
                  BillRow(
                    title: 'Maison Mpita',
                    subtitle: '417,4 kWh · échéance le 18 nov.',
                    amount: 31420,
                    status: billStatus('unpaid'),
                    onTap: () {},
                  ),
                  BillRow(
                    title: 'Boutique Tié-Tié',
                    subtitle: 'Payée le 12 sept. par Grâce Ngoma',
                    amount: 25818,
                    status: billStatus('paid'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s4),
            AllPaidCard(nextBillDate: DateTime(2027, 1, 3)),

            const _Section('États d’écran'),
            const StateBlock.empty(
              title: 'Aucune facture pour l’instant',
              message: 'Ajoutez un compteur pour les voir ici.',
            ),
            StateBlock.error(
              what: 'vos factures',
              onRetry: () {},
              reference: 'app-k3v9q2x7m1z8c4b6n0p5',
            ),
            StateBlock.offline(onRetry: () {}),
            const StateBlock.accessDenied(message: householdNotShared),
            AppButton(
              label: 'Feuille « session expirée »',
              variant: ButtonVariant.secondary,
              onPressed: () =>
                  showSessionExpiredSheet(context, onReconnect: () => Navigator.of(context).pop()),
            ),

            const _Section('Paiement'),
            AppButton(
              label: 'Ouvrir la feuille de paiement',
              variant: ButtonVariant.secondary,
              onPressed: () => _openPayment(context),
            ),
            for (final phase in TransactionPhase.values) ...[
              const SizedBox(height: Space.s6),
              TransactionStatusView(
                phase: phase,
                amount: 31420,
                operatorLabel: 'MTN MoMo',
                phone: '+242061234567',
                reference: 'TX-2026-004812',
                failureReason:
                    'Le paiement a échoué : solde Mobile Money insuffisant. Rechargez votre '
                    'compte puis réessayez.',
                onViewReceipt: () {},
                onRetry: () {},
                onHome: () {},
              ),
            ],

            const _Section('Navigation'),
            AppButton(
              label: 'Ouvrir les écrans principaux',
              variant: ButtonVariant.secondary,
              onPressed: () => context.go(AppTab.home.path),
            ),
            const SizedBox(height: Space.s4),
            AppBottomNav(
              current: _tab,
              onTab: (tab) => setState(() => _tab = tab),
              online: _online,
              billsOverdue: true,
              onPay: () => _openPayment(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPayment(BuildContext context) => showPaymentSheet(
    context,
    periodLabel: formatBillPeriodShort(DateTime(2026, 9), DateTime(2026, 10, 31)),
    householdName: 'Maison Mpita',
    amount: 31420,
    defaultPhone: '+242061234567',
    online: _online,
    onPay: (operator, phone) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (context.mounted) Navigator.of(context).pop();
    },
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.s8, bottom: Space.s3),
    child: Semantics(
      header: true,
      child: Text(title, style: AppText.h2.copyWith(color: context.colors.ink)),
    ),
  );
}

class _Switch extends StatelessWidget {
  const _Switch(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: AppText.bodyStrong.copyWith(color: context.colors.ink)),
    value: value,
    onChanged: onChanged,
  );
}
