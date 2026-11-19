import 'dart:async';

import 'package:flutter/material.dart';

import '../format/numbers.dart';
import '../format/phone.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.g.dart';
import 'app_text_field.dart';
import 'bottom_sheet.dart';
import 'pay_button.dart';

/// Opérateurs Mobile Money (`MobileOperator` du contrat, un test le vérifie), écrits en toutes
/// lettres tant que les logos officiels ne sont pas fournis (charte).
enum PaymentOperator {
  mtn('mtn', 'MTN MoMo'),
  airtel('airtel', 'Airtel Money');

  const PaymentOperator(this.apiValue, this.label);

  /// Valeur envoyée à l'API.
  final String apiValue;
  final String label;
}

/// Opérateur d'un numéro normalisé (« +242061234567 »), mêmes règles que le backend
/// (`backend/docs/PAIEMENTS.md` : MTN = 06, Airtel = 05 et 04, « hypothèse à confirmer »).
/// `null` : pas un numéro Mobile Money (fixe 22…).
PaymentOperator? operatorForPhone(String normalized) {
  if (normalized.startsWith('+24206')) return PaymentOperator.mtn;
  if (normalized.startsWith('+24205') || normalized.startsWith('+24204')) {
    return PaymentOperator.airtel;
  }
  return null;
}

/// Message sous le champ si le numéro ne va pas avec l'opérateur choisi (`null` : il va).
String? operatorMismatch(String normalized, PaymentOperator chosen) {
  final actual = operatorForPhone(normalized);
  if (actual == null) return 'Ce numéro ne peut pas payer en Mobile Money.';
  if (actual == chosen) return null;
  return switch (chosen) {
    PaymentOperator.mtn => 'Ce numéro n’est pas un numéro MTN MoMo (numéros en 06).',
    PaymentOperator.airtel => 'Ce numéro n’est pas un numéro Airtel Money (numéros en 05 ou 04).',
  };
}

/// Contenu de la feuille de paiement (maquette de l'écran 8, `frontend/design/components/
/// PaymentSheet`). L'envoi (clé d'idempotence, suivi) est fait par l'appelant, dans `onPay`
/// (`lib/features/payments/`).
///
/// - le montant vient de la facture et n'est JAMAIS saisi ;
/// - le numéro est prérempli avec celui du compte, modifiable (payer pour un proche) ;
/// - l'opérateur est proposé d'après ce numéro (06 → MTN, 05 / 04 → Airtel), modifiable ; un
///   numéro qui ne va pas avec l'opérateur choisi est refusé AVANT l'envoi (D6.2) ;
/// - un autre numéro que celui du compte : « Le titulaire de ce numéro recevra la demande… » (D6.3) ;
/// - un seul envoi, même si l'on touche deux fois (bouton en chargement) ;
/// - hors ligne : Payer désactivé, « Connexion nécessaire pour payer ».
class PaymentSheetContent extends StatefulWidget {
  const PaymentSheetContent({
    required this.periodLabel,
    required this.householdName,
    required this.amount,
    required this.defaultPhone,
    required this.online,
    required this.onPay,
    this.error,
    super.key,
  });

  /// Refus de l'API à afficher au-dessus de Payer (numéro refusé, facture déjà payée…).
  final String? error;

  /// « sept.–oct. 2026 ».
  final String periodLabel;
  final String householdName;
  final int amount;

  /// Numéro du compte (« +242061234567 »), prérempli.
  final String defaultPhone;
  final bool online;

  /// Lance le paiement avec l'opérateur choisi et le numéro normalisé (« +242061234567 »).
  final Future<void> Function(PaymentOperator operator, String phone) onPay;

  @override
  State<PaymentSheetContent> createState() => _PaymentSheetContentState();
}

class _PaymentSheetContentState extends State<PaymentSheetContent> {
  late PaymentOperator _operator = operatorForPhone(widget.defaultPhone) ?? PaymentOperator.mtn;
  late final _phone = TextEditingController(
    text: CongoPhoneInputFormatter.group(widget.defaultPhone.replaceFirst('+242', '')),
  )..addListener(_onPhoneChanged);
  String? _phoneError;
  bool _forSomeoneElse = false;

  /// Texte affiché quand on paie depuis le numéro d'un proche.
  static const someoneElseNote = 'Le titulaire de ce numéro recevra la demande de confirmation.';

  void _onPhoneChanged() {
    String? normalized;
    try {
      normalized = normalizeCongoPhone(_phone.text);
    } on Object {
      normalized = null;
    }
    final other = normalized != null && normalized != widget.defaultPhone;
    if (other != _forSomeoneElse) setState(() => _forSomeoneElse = other);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final error =
        phoneError(_phone.text) ?? operatorMismatch(normalizeCongoPhone(_phone.text), _operator);
    setState(() => _phoneError = error);
    if (error != null) return;
    await widget.onPay(_operator, normalizeCongoPhone(_phone.text));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Facture de ${widget.periodLabel} · ${widget.householdName}'.toUpperCase(),
          style: AppText.overline.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: Space.s1),
        Text(formatFcfa(widget.amount), style: AppText.amountHero.copyWith(color: c.ink)),
        const SizedBox(height: Space.s5),
        Semantics(
          header: true,
          child: Text('MOYEN DE PAIEMENT', style: AppText.overline.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(height: Space.s2),
        for (final operator in PaymentOperator.values) ...[
          _OperatorChoice(
            operator: operator,
            selected: operator == _operator,
            onTap: () => setState(() => _operator = operator),
          ),
          const SizedBox(height: Space.s2),
        ],
        const SizedBox(height: Space.s3),
        PhoneField(
          controller: _phone,
          label: 'Numéro ${_operator.label}',
          helper: 'Vous pouvez payer depuis le numéro d’un proche.',
          error: _phoneError,
        ),
        if (_forSomeoneElse) ...[
          const SizedBox(height: Space.s2),
          Text(
            someoneElseNote,
            key: const Key('payment.someoneElse'),
            style: AppText.bodySm.copyWith(color: c.currentText),
          ),
        ],
        if (widget.error case final message?) ...[
          const SizedBox(height: Space.s4),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: const Key('payment.error'),
              style: AppText.bodySm.copyWith(color: c.errorText, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: Space.s5),
        PayButton(amount: widget.amount, online: widget.online, onPay: _pay),
        const SizedBox(height: Space.s2),
        Text(
          'Le montant est celui de la facture ; il ne peut pas être modifié.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

/// Un moyen de paiement : choix exclusif ; actif = contour `volt` et fond `volt-soft`.
class _OperatorChoice extends StatelessWidget {
  const _OperatorChoice({required this.operator, required this.selected, required this.onTap});

  final PaymentOperator operator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${operator.label}, confirmation par code PIN sur votre téléphone',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.voltSoft : c.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
          side: BorderSide(color: selected ? c.volt : c.line, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Motion.of(context, Motion.press),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? c.volt : c.line, width: 2),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: c.volt, shape: BoxShape.circle),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(operator.label, style: AppText.bodyStrong.copyWith(color: c.ink)),
                        Text(
                          'Confirmation par code PIN sur votre téléphone',
                          style: AppText.bodySm.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ouvre la feuille de paiement (verre, un des deux usages permis).
Future<void> showPaymentSheet(
  BuildContext context, {
  required String periodLabel,
  required String householdName,
  required int amount,
  required String defaultPhone,
  required bool online,
  required Future<void> Function(PaymentOperator operator, String phone) onPay,
}) => showAppSheet<void>(
  context,
  child: PaymentSheetContent(
    periodLabel: periodLabel,
    householdName: householdName,
    amount: amount,
    defaultPhone: defaultPhone,
    online: online,
    onPay: onPay,
  ),
);
