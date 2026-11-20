import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/households.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/form_message.dart';
import 'households_data.dart';
import 'households_rules.dart';

/// Ouvre la feuille « Ajouter un compteur ». `owned` : mes foyers (ceux où je suis propriétaire) ;
/// vide → un nouveau foyer est créé avec le compteur.
Future<void> showAddMeterSheet(BuildContext context, {required List<HouseholdSummary> owned}) =>
    showAppSheet<void>(context, child: AddMeterSheet(owned: owned));

/// Feuille « Ajouter un compteur » (maquette `Compteurs.dc.html`) : N° de branchement et N° client
/// de la facture E²C, vérifiés par l'API chez E²C (`BillingSource`) au moment de l'ajout ; foyer
/// existant ou nouveau. L'API n'a pas de vérification séparée : le bouton ajoute directement.
/// Les erreurs de l'API s'affichent sous le bon champ.
class AddMeterSheet extends ConsumerStatefulWidget {
  const AddMeterSheet({required this.owned, super.key});

  final List<HouseholdSummary> owned;

  @override
  ConsumerState<AddMeterSheet> createState() => _AddMeterSheetState();
}

class _AddMeterSheetState extends ConsumerState<AddMeterSheet> {
  final _reference = TextEditingController();
  final _customer = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();

  /// Foyer choisi ; `null` : nouveau foyer.
  late int? _household = widget.owned.firstOrNull?.id;

  /// Foyer déjà créé par une tentative précédente (jamais créé deux fois).
  int? _created;

  String? _referenceError;
  String? _customerError;
  String? _nameError;
  String? _cityError;
  String? _message;
  String? _requestReference;
  MeterAddResponse? _result;

  @override
  void dispose() {
    _reference.dispose();
    _customer.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _referenceError = addMeterFieldError('reference', _reference.text);
      _customerError = addMeterFieldError('customer_number', _customer.text);
      _nameError = _household == null ? addMeterFieldError('name', _name.text) : null;
      _cityError = _household == null ? addMeterFieldError('city', _city.text) : null;
      _message = null;
      _requestReference = null;
    });
    return [_referenceError, _customerError, _nameError, _cityError].every((e) => e == null);
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final actions = ref.read(householdActionsProvider);
    try {
      final householdId =
          _household ??
          _created ??
          (await actions.createHousehold(
            HouseholdCreate(name: _name.text.trim(), city: _city.text.trim()),
          )).id;
      _created = _household == null ? householdId : null;
      final result = await actions.addMeter(
        householdId,
        MeterAddRequest(reference: _reference.text.trim(), customerNumber: _customer.text.trim()),
      );
      if (mounted) setState(() => _result = result);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _show(failure));
    }
  }

  void _show(ApiFailure failure) {
    switch (failure) {
      case ApiRejected(code: 'E2C_METER_NOT_FOUND' || 'METER_ALREADY_LINKED'):
        _referenceError = failure.message;
      case InvalidFields(:final fields):
        const refused = 'Valeur refusée par ElecPay : vérifiez ce champ.';
        if (fields.containsKey('reference')) _referenceError = refused;
        if (fields.containsKey('customer_number')) _customerError = refused;
        if (fields.containsKey('name')) _nameError = refused;
        if (fields.containsKey('city')) _cityError = refused;
        _message = failure.message;
      case TooManyRequests():
        _message = 'Trop de tentatives. Réessayez dans un moment.';
      default:
        _message = failure.message;
        _requestReference = failure.reference;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(child: _result == null ? _form(c) : _success(c, _result!)),
      ),
    );
  }

  Widget _form(ElecPayColors c) => Column(
    key: const Key('addMeter.form'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text('Ajouter un compteur', style: AppText.h2.copyWith(color: c.ink)),
      ),
      const SizedBox(height: Space.s1),
      Text(
        'Les deux numéros figurent en haut de votre facture E²C.',
        style: AppText.bodySm.copyWith(color: c.inkMuted),
      ),
      const SizedBox(height: Space.s4),
      AppTextField(
        key: const Key('addMeter.reference'),
        label: 'N° de branchement',
        controller: _reference,
        helper: 'Ex. 0018 09 5408',
        error: _referenceError,
        mono: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() => _referenceError = null),
      ),
      const SizedBox(height: Space.s3),
      AppTextField(
        key: const Key('addMeter.customer'),
        label: 'N° client',
        controller: _customer,
        helper: 'Ex. 0758340H',
        error: _customerError,
        mono: true,
        textInputAction: _household == null ? TextInputAction.next : TextInputAction.done,
        onChanged: (_) => setState(() => _customerError = null),
      ),
      if (widget.owned.isNotEmpty) ...[
        const SizedBox(height: Space.s4),
        Text('Foyer', style: AppText.bodySm.copyWith(color: c.inkMuted)),
        const SizedBox(height: Space.s2),
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            for (final h in widget.owned)
              _Choice(
                key: Key('addMeter.household.${h.id}'),
                label: h.name,
                selected: _household == h.id,
                onTap: () => setState(() => _household = h.id),
              ),
            _Choice(
              key: const Key('addMeter.household.new'),
              label: 'Nouveau foyer',
              selected: _household == null,
              onTap: () => setState(() => _household = null),
            ),
          ],
        ),
      ],
      if (_household == null) ...[
        const SizedBox(height: Space.s3),
        AppTextField(
          key: const Key('addMeter.name'),
          label: 'Nom du foyer',
          controller: _name,
          helper: 'Ex. Maison Mpaka',
          error: _nameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _nameError = null),
        ),
        const SizedBox(height: Space.s3),
        AppTextField(
          key: const Key('addMeter.city'),
          label: 'Ville',
          controller: _city,
          helper: 'Ex. Pointe-Noire',
          error: _cityError,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _cityError = null),
        ),
      ],
      if (_message case final message?) ...[
        const SizedBox(height: Space.s3),
        FormMessage(message, reference: _requestReference),
      ],
      const SizedBox(height: Space.s4),
      AppButton(
        key: const Key('addMeter.submit'),
        label: 'Ajouter ce compteur',
        loadingLabel: 'Vérification chez E²C…',
        onPressed: _submit,
      ),
    ],
  );

  Widget _success(ElecPayColors c, MeterAddResponse result) => Column(
    key: const Key('addMeter.success'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.successSoft,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.check, color: c.success),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compteur ajouté', style: AppText.bodyStrong.copyWith(color: c.ink)),
                    Text(
                      addedMeterLine(result.meter),
                      style: AppText.bodySm.copyWith(color: c.inkMuted),
                    ),
                    Text(
                      importedHistoryLine(result.history),
                      style: AppText.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.s4),
      AppButton(
        key: const Key('addMeter.done'),
        label: 'Terminé',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap, super.key});

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
        color: selected ? c.voltSoft : c.surface1,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.volt : c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s2),
              child: Text(
                label,
                style: AppText.bodySm.copyWith(color: c.ink, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
