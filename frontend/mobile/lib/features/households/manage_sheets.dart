import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formats.dart';
import '../../core/models/households.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/form_message.dart';
import 'households_data.dart';
import 'households_rules.dart';

// Gestion d'un foyer (F8.4, D8.1) : inviter, retirer un membre ou annuler une invitation, quitter,
// renommer le foyer ou un compteur. Chaque action destructive demande une confirmation. Les
// boutons suivent `can_manage` (le serveur décide, l'écran suit).

/// Petit message en bas de l'écran (résultat d'une action, ou refus de l'API).
void sayIn(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Confirmation d'une action destructive : `true` si confirmée.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showAppSheet<bool>(
      context,
      child: Column(
        key: const Key('manage.confirm'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppText.h2.copyWith(color: context.colors.ink)),
          ),
          const SizedBox(height: Space.s2),
          Text(message, style: AppText.body.copyWith(color: context.colors.inkMuted)),
          const SizedBox(height: Space.s4),
          Builder(
            builder: (context) => AppButton(
              key: const Key('manage.confirm.yes'),
              label: confirmLabel,
              variant: ButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: Space.s2),
          Builder(
            builder: (context) => AppButton(
              key: const Key('manage.confirm.no'),
              label: 'Annuler',
              variant: ButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ],
      ),
    ) ??
    false;

/// Ouvre la feuille « Gérer » d'un foyer.
Future<void> showManageSheet(BuildContext context, int householdId) =>
    showAppSheet<void>(context, child: ManageSheet(householdId: householdId));

/// Ouvre la feuille « Inviter un proche ».
Future<void> showInviteSheet(BuildContext context, HouseholdDetail household) =>
    showAppSheet<void>(context, child: InviteSheet(household: household));

/// Feuille « Gérer » : propriétaire → renommer, compteurs, membres, inviter ; membre → quitter.
class ManageSheet extends ConsumerWidget {
  const ManageSheet({required this.householdId, super.key});

  final int householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final household = ref.watch(householdDetailProvider(householdId)).value?.data;
    if (household == null) {
      return const Padding(
        padding: EdgeInsets.all(Space.s6),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(householdActionsProvider);
    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        sayIn(messenger, done);
      } on ApiFailure catch (failure) {
        sayIn(messenger, failure.message);
      }
    }

    final owner = household.canManage;
    final members = household.members.where((m) => m.status != MemberStatuses.revoked).toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('manage.sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(household.name, style: AppText.h2.copyWith(color: c.ink)),
            ),
            Text(
              householdPlaceLine(household.district, household.city, household.myRole),
              style: AppText.bodySm.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.s4),
            if (owner) ...[
              AppButton(
                key: const Key('manage.renameHousehold'),
                label: 'Renommer le foyer',
                variant: ButtonVariant.secondary,
                onPressed: () => showRenameSheet(
                  context,
                  title: 'Renommer le foyer',
                  label: 'Nom du foyer',
                  initial: household.name,
                  required: true,
                  onSave: (name) => actions.renameHousehold(household.id, name!),
                ),
              ),
              for (final m in household.meters) ...[
                const SizedBox(height: Space.s3),
                _Line(
                  key: Key('manage.meter.${m.id}'),
                  title: meterCardName(m),
                  subtitle: formatReference(m.reference),
                  action: 'Renommer',
                  onAction: () => showRenameSheet(
                    context,
                    title: 'Renommer le compteur',
                    label: 'Nom du compteur (facultatif)',
                    helper: 'Ex. Cuisine, Boutique. Vide : pas de nom.',
                    initial: m.label ?? '',
                    required: false,
                    onSave: (label) => actions.renameMeter(household.id, m.id, label),
                  ),
                ),
              ],
              const SizedBox(height: Space.s4),
              Text('MEMBRES', style: AppText.overline.copyWith(color: c.inkMuted)),
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s2),
                  child: Text('Vous seul.', style: AppText.bodySm.copyWith(color: c.inkMuted)),
                ),
              for (final m in members) ...[
                const SizedBox(height: Space.s2),
                _Line(
                  key: Key('manage.member.${m.id}'),
                  title: m.person.fullName,
                  subtitle: [
                    memberRoleLabel(m.role),
                    m.person.phoneMasked,
                    if (m.status == MemberStatuses.invited) 'invitation en attente',
                  ].join(' · '),
                  action: m.status == MemberStatuses.invited ? 'Annuler' : 'Retirer',
                  onAction: () async {
                    final invited = m.status == MemberStatuses.invited;
                    final ok = await confirmAction(
                      context,
                      title: invited ? 'Annuler l’invitation ?' : 'Retirer ce membre ?',
                      message: invited
                          ? '${m.person.fullName} ne pourra plus rejoindre ${household.name}.'
                          : '${m.person.fullName} ne verra plus les factures de '
                                '${household.name} et ne pourra plus les payer.',
                      confirmLabel: invited ? 'Annuler l’invitation' : 'Retirer',
                    );
                    if (!ok) return;
                    await run(
                      () => actions.removeMember(household.id, m.id),
                      invited ? 'Invitation annulée.' : '${m.person.fullName} a été retiré.',
                    );
                  },
                ),
              ],
              const SizedBox(height: Space.s4),
              AppButton(
                key: const Key('manage.invite'),
                label: 'Inviter un proche',
                onPressed: () => unawaited(showInviteSheet(context, household)),
              ),
            ] else ...[
              Text(
                'Vous êtes ${memberRoleLabel(household.myRole)} de ce foyer. Seul le '
                'propriétaire (${household.owner.fullName}) peut le modifier.',
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s4),
              AppButton(
                key: const Key('manage.leave'),
                label: 'Quitter ce foyer',
                variant: ButtonVariant.danger,
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Quitter ${household.name} ?',
                    message:
                        'Vous ne verrez plus ses factures et ne pourrez plus les payer. Pour '
                        'revenir, il faudra une nouvelle invitation.',
                    confirmLabel: 'Quitter le foyer',
                  );
                  if (!ok || !context.mounted) return;
                  final navigator = Navigator.of(context);
                  await run(() async {
                    await actions.leave(household.id);
                    navigator.pop();
                  }, 'Vous avez quitté ${household.name}.');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final String action;
  final FutureOr<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.s3, Space.s2, Space.s2, Space.s2),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s2,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.bodyStrong.copyWith(color: c.ink)),
              Text(subtitle, style: AppText.caption.copyWith(color: c.inkMuted)),
            ],
          ),
          AppButton(label: action, variant: ButtonVariant.ghost, onPressed: onAction),
        ],
      ),
    );
  }
}

/// Feuille « Inviter un proche » : numéro d'un compte ElecPay existant, rôle (payeur délégué ou
/// lecteur). D8.2 : sans compte, on demande à la personne de s'inscrire (aucun SMS envoyé).
class InviteSheet extends ConsumerStatefulWidget {
  const InviteSheet({required this.household, super.key});

  final HouseholdDetail household;

  @override
  ConsumerState<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<InviteSheet> {
  final _phone = TextEditingController();
  MemberRole _role = HouseholdRoles.payer;
  String? _phoneError;
  String? _message;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final phone = PhoneField.normalized(_phone.text);
    setState(() {
      _phoneError = phone == null ? phoneError(_phone.text) : null;
      _message = null;
    });
    if (phone == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(householdActionsProvider)
          .invite(widget.household.id, InviteRequest(phone: phone, role: _role));
      navigator.pop();
      sayIn(messenger, inviteSentMessage(formatPhone(phone)));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure) {
          case ApiRejected(code: 'INVITEE_NOT_FOUND'):
            _phoneError = inviteeWithoutAccount;
          case ApiRejected(code: 'ALREADY_MEMBER' || 'INVALID_INVITEE'):
            _phoneError = failure.message;
          default:
            _message = failure.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('invite.sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Inviter un proche', style: AppText.h2.copyWith(color: c.ink)),
            ),
            const SizedBox(height: Space.s1),
            Text(
              'Dans ${widget.household.name}. La personne doit déjà avoir un compte ElecPay ; '
              'elle devra accepter l’invitation.',
              style: AppText.bodySm.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.s4),
            PhoneField(
              key: const Key('invite.phone'),
              controller: _phone,
              label: 'Son numéro de téléphone',
              error: _phoneError,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _phoneError = null),
            ),
            const SizedBox(height: Space.s4),
            for (final role in [HouseholdRoles.payer, HouseholdRoles.viewer])
              _RoleChoice(
                key: Key('invite.role.$role'),
                title: householdRoleLabel(role),
                detail: role == HouseholdRoles.payer
                    ? 'Voit et paie les factures du foyer.'
                    : 'Voit les factures et la consommation, sans payer.',
                selected: _role == role,
                onTap: () => setState(() => _role = role),
              ),
            if (_message case final message?) ...[
              const SizedBox(height: Space.s3),
              FormMessage(message),
            ],
            const SizedBox(height: Space.s4),
            AppButton(
              key: const Key('invite.send'),
              label: 'Envoyer l’invitation',
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: Semantics(
        selected: selected,
        button: true,
        inMutuallyExclusiveGroup: true,
        label: '$title. $detail',
        excludeSemantics: true,
        child: Material(
          color: selected ? c.voltSoft : c.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            side: BorderSide(color: selected ? c.volt : c.line),
          ),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Space.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyStrong.copyWith(color: c.ink)),
                  Text(detail, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feuille « Renommer » (foyer ou compteur). `required: false` : vide = retirer le nom (`null`).
Future<void> showRenameSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  required bool required,
  required Future<void> Function(String? value) onSave,
  String? helper,
}) => showAppSheet<void>(
  context,
  child: _RenameSheet(
    title: title,
    label: label,
    initial: initial,
    required: required,
    helper: helper,
    onSave: onSave,
  ),
);

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({
    required this.title,
    required this.label,
    required this.initial,
    required this.required,
    required this.onSave,
    this.helper,
  });

  final String title;
  final String label;
  final String initial;
  final bool required;
  final String? helper;
  final Future<void> Function(String? value) onSave;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _value = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _value.text.trim();
    if (widget.required && text.isEmpty) {
      setState(() => _error = 'Saisissez un nom.');
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(text.isEmpty ? null : text);
      navigator.pop();
      sayIn(messenger, 'Nom enregistré.');
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          key: const Key('rename.sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(widget.title, style: AppText.h2.copyWith(color: c.ink)),
            ),
            const SizedBox(height: Space.s4),
            AppTextField(
              key: const Key('rename.value'),
              label: widget.label,
              controller: _value,
              helper: widget.helper,
              error: _error,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: Space.s4),
            AppButton(key: const Key('rename.save'), label: 'Enregistrer', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
