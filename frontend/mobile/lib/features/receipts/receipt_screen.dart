import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/cached_api.dart';
import '../../core/documents/documents.dart';
import '../../core/format/formats.dart';
import '../../core/models/receipts.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../home/home_screen.dart' show homeClockProvider;

/// Reçu (`GET /receipts/{id}`, en cache : un reçu ne change jamais). Le PDF, lui, n'est jamais
/// en cache (`GET /receipts/{id}/pdf`, à la demande).
final receiptProvider = FutureProvider.family<Fetched<ReceiptPublic>, int>(
  (ref, receiptId) =>
      ref.watch(cachedApiProvider).get('/receipts/$receiptId', ReceiptPublic.fromJson),
);

/// Écran 10 : reçu d'un paiement réussi (maquette `Recu.dc.html`) : numéro EP-…, montant, facture,
/// foyer, payeur, moyen (numéro toujours masqué), date, transaction, code de vérification, Mode
/// démo ; Télécharger (ouvrir le PDF) et Partager, désactivés hors ligne ; Terminé.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({required this.receiptId, super.key});

  final int receiptId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _busy = false;

  /// Télécharge le PDF du reçu, puis l'ouvre (`share: false`) ou le partage. Un seul à la fois.
  Future<void> _pdf(ReceiptPublic receipt, {required bool share}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    void say(String text, {SnackBarAction? action}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
    final actions = ref.read(documentActionsProvider);
    final subject = 'Reçu ElecPay ${formatReference(receipt.number)}';
    try {
      final file = await ref
          .read(documentDownloaderProvider)
          .download('/receipts/${receipt.id}/pdf', documentFileName('recu', receipt.number));
      if (share) {
        await actions.share(file.path, subject: subject);
      } else {
        switch (await actions.open(file.path)) {
          case OpenOutcome.opened:
            break;
          case OpenOutcome.noApp:
            say(
              'Aucune application pour ouvrir le PDF.',
              action: SnackBarAction(
                label: 'Partager',
                onPressed: () => unawaited(actions.share(file.path, subject: subject)),
              ),
            );
          case OpenOutcome.failed:
            say('Impossible d’ouvrir le PDF. Réessayez dans un instant.');
        }
      }
    } on ApiFailure catch (failure) {
      say([failure.message, if (failure.reference case final r?) 'Référence : $r'].join(' '));
    } on Object {
      say('Impossible d’enregistrer le PDF sur le téléphone.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done() => context.go(AppTab.home.path);

  Future<void> _refresh() async {
    ref.invalidate(receiptProvider(widget.receiptId));
    try {
      await ref.read(receiptProvider(widget.receiptId).future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = ref.watch(receiptProvider(widget.receiptId));
    void retry() => unawaited(_refresh());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu'),
        leading: IconButton(
          tooltip: 'Fermer',
          onPressed: _done,
          icon: const AppIcon(AppIcons.cross),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: switch (receipt) {
            AsyncValue(value: final fetched?) => _content(fetched),
            AsyncError(:final error) => ListView(
              children: [
                if (error case final ApiFailure failure)
                  stateForFailure(failure, what: 'ce reçu', onRetry: retry)
                else
                  StateBlock.error(what: 'ce reçu', onRetry: retry),
              ],
            ),
            _ => ListView(
              padding: const EdgeInsets.all(Space.s4),
              children: [
                AppSkeleton(
                  loading: true,
                  child: _ReceiptCard(receipt: ReceiptPublic.fromJson(_skeletonReceipt)),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  Widget _content(Fetched<ReceiptPublic> fetched) {
    final c = context.colors;
    final r = fetched.data;
    final online = fetched is FreshData<ReceiptPublic>;
    return ListView(
      key: const Key('receipt.screen'),
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s6),
      children: [
        if (fetched case final CachedData<ReceiptPublic> cached) ...[
          OfflineBanner(cached.label),
          const SizedBox(height: Space.s3),
        ],
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
            child: AppIcon(AppIcons.check, size: 30, color: c.success),
          ),
        ),
        const SizedBox(height: Space.s3),
        Semantics(
          header: true,
          child: Text(
            'Paiement réussi',
            textAlign: TextAlign.center,
            style: AppText.h1.copyWith(color: c.ink),
          ),
        ),
        const SizedBox(height: Space.s1),
        Text(
          'La facture de ${formatBillPeriodLong(r.billPeriodStart, r.billPeriodEnd)} est payée.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: Space.s5),
        _ReceiptCard(receipt: r),
        const SizedBox(height: Space.s5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppButton(
                key: const Key('receipt.download'),
                label: 'Télécharger',
                icon: AppIcons.bill,
                variant: ButtonVariant.secondary,
                loading: _busy,
                onPressed: online ? () => _pdf(r, share: false) : null,
              ),
            ),
            const SizedBox(width: Space.s2),
            Expanded(
              child: AppButton(
                key: const Key('receipt.share'),
                label: 'Partager',
                icon: AppIcons.share,
                variant: ButtonVariant.secondary,
                onPressed: online && !_busy ? () => _pdf(r, share: true) : null,
              ),
            ),
          ],
        ),
        if (!online) ...[
          const SizedBox(height: Space.s2),
          Text(
            'Connexion nécessaire pour le PDF',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: c.inkMuted),
          ),
        ],
        const SizedBox(height: Space.s3),
        AppButton(key: const Key('receipt.done'), label: 'Terminé', onPressed: _done),
      ],
    );
  }
}

/// La carte du reçu (maquette) : en-tête ElecPay + numéro + Mode démo, montant, puis le détail.
class _ReceiptCard extends ConsumerWidget {
  const _ReceiptCard({required this.receipt});

  final ReceiptPublic receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final r = receipt;
    final now = ref.read(homeClockProvider)();
    final rows = <(String, String, bool)>[
      (
        'Facture',
        '${formatBillPeriodShort(r.billPeriodStart, r.billPeriodEnd)} · '
            '${formatReference(r.billReference)}',
        false,
      ),
      ('Foyer', [?r.householdName, r.meterReference].join(' · '), false),
      ('Payé par', r.payerName, false),
      ('Moyen', '${r.operatorLabel} · ${formatPhone(r.phoneNumber)}', false),
      ('Date', formatDateTime(r.issuedAt, now: now), false),
      ('Transaction', formatReference(r.transactionReference), true),
      ('Vérification', r.verificationCode, true),
    ];
    return Container(
      key: const Key('receipt.card'),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
        boxShadow: context.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ElecPay', style: AppText.bodyStrong.copyWith(color: c.ink)),
                  Text(
                    'Reçu ${formatReference(r.number)}',
                    style: AppText.reference.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
              if (r.source == 'simulated') const DemoBadge(),
            ],
          ),
          const SizedBox(height: Space.s4),
          Text('Montant payé', style: AppText.caption.copyWith(color: c.inkMuted)),
          Semantics(
            label: formatFcfa(r.amount),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatFcfaValue(r.amount),
                    style: AppText.amountHero.copyWith(color: c.ink),
                  ),
                  TextSpan(
                    text: '${unitSpace}FCFA',
                    style: AppText.body.copyWith(color: c.inkMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s3),
          Divider(height: 1, color: c.line),
          for (final (label, value, mono) in rows)
            Semantics(
              container: true,
              label: '$label : $value',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(top: Space.s3),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: Space.s3,
                  children: [
                    Text(label, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                    Text(
                      value,
                      style: (mono ? AppText.reference : AppText.bodySm).copyWith(
                        color: c.ink,
                        fontWeight: mono ? null : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reçu d'exemple du squelette de chargement (forme seulement).
const _skeletonReceipt = <String, Object?>{
  'id': 0,
  'number': 'EP-2026-000123',
  'issued_at': '2026-11-12T13:32:00Z',
  'amount': 31420,
  'verification_code': '8F3K-2Q9M-7XHT',
  'bill_id': 0,
  'bill_reference': '20261103000127',
  'bill_period_label': '',
  'bill_period_start': '2026-09-01',
  'bill_period_end': '2026-10-31',
  'meter_id': 0,
  'meter_reference': '0412-8833',
  'household_id': 0,
  'household_name': 'Maison Mpita',
  'payer_id': 0,
  'payer_name': 'Loick Makosso',
  'is_mine': true,
  'operator': 'mtn',
  'operator_label': 'MTN MoMo',
  'phone_number': '+242 06 ••• 45 67',
  'transaction_id': 0,
  'transaction_reference': 'TX-00000001',
  'source': 'simulated',
};
