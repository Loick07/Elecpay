import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/formats.dart';
import '../../core/models/account.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_message.dart';
import '../../core/widgets/state_block.dart';
import '../auth/models/auth_models.dart';
import '../auth/validation.dart';
import '../home/home_data.dart';
import 'account_data.dart';

/// « Modifier » de l'écran 14 : nom et e-mail ; vérification de l'e-mail par un code (les reçus
/// partent seulement vers une adresse vérifiée). Le numéro de téléphone (identifiant) ne change pas.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(homeUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: switch (user) {
          // Clé par compte et par version : le formulaire repart des valeurs enregistrées.
          AsyncValue(:final value?) => _ProfileForm(
            key: ValueKey('${value.data.id}.${value.data.email}.${value.data.emailVerifiedAt}'),
            user: value.data,
          ),
          AsyncError(:final error) => ListView(
            children: [
              if (error case final ApiFailure failure)
                stateForFailure(
                  failure,
                  what: 'votre profil',
                  onRetry: () => ref.invalidate(homeUserProvider),
                )
              else
                StateBlock.error(
                  what: 'votre profil',
                  onRetry: () => ref.invalidate(homeUserProvider),
                ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user, super.key});

  final UserPublic user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  final _code = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _codeError;
  String? _message;
  VerificationSent? _sent;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Champs changés seulement (un e-mail vide retire l'adresse).
  Map<String, Object?> get _changes {
    final name = normalizeFullName(_name.text);
    final email = normalizeEmail(_email.text);
    return {
      if (name != widget.user.fullName) 'full_name': name,
      if (email != widget.user.email) 'email': email,
    };
  }

  Future<void> _save() async {
    setState(() {
      _nameError = fullNameError(_name.text);
      _emailError = emailError(_email.text);
      _message = null;
    });
    if (_nameError != null || _emailError != null) return;
    final changes = _changes;
    if (changes.isEmpty) {
      _say('Aucune modification.');
      return;
    }
    try {
      await ref.read(accountActionsProvider).updateProfile(changes);
      if (mounted) _say('Profil enregistré.');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure) {
          case ApiRejected(code: 'EMAIL_ALREADY_USED'):
            _emailError = failure.message;
          case InvalidFields(:final fields):
            const refused = 'Valeur refusée par ElecPay : vérifiez ce champ.';
            if (fields.containsKey('full_name')) _nameError = refused;
            if (fields.containsKey('email')) _emailError = refused;
            _message = failure.message;
          default:
            _message = failure.message;
        }
      });
    }
  }

  Future<void> _sendCode() async {
    try {
      final sent = await ref.read(accountActionsProvider).sendEmailCode();
      if (mounted) setState(() => _sent = sent);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _message = failure.message);
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Saisissez le code reçu.');
      return;
    }
    try {
      await ref.read(accountActionsProvider).confirmEmail(code);
      if (mounted) _say('Adresse e-mail vérifiée.');
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _codeError = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = widget.user;
    final email = user.email;
    final verified = user.emailVerifiedAt != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s8),
      child: Column(
        key: const Key('profile.form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('profile.name'),
            label: 'Nom complet',
            controller: _name,
            error: _nameError,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: Space.s3),
          Semantics(
            container: true,
            label: 'Numéro de téléphone : ${formatPhone(user.phone)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Numéro de téléphone', style: AppText.bodySm.copyWith(color: c.inkMuted)),
                Text(formatPhone(user.phone), style: AppText.body.copyWith(color: c.ink)),
                Text(
                  'Il sert à vous connecter : il ne se change pas ici.',
                  style: AppText.caption.copyWith(color: c.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.s3),
          AppTextField(
            key: const Key('profile.email'),
            label: 'Adresse e-mail (facultative)',
            controller: _email,
            helper: 'Pour recevoir vos reçus par e-mail, une fois l’adresse vérifiée.',
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          if (email != null) ...[
            const SizedBox(height: Space.s2),
            Row(
              key: const Key('profile.emailStatus'),
              children: [
                AppIcon(
                  verified ? AppIcons.check : AppIcons.info,
                  size: 16,
                  color: verified ? c.successText : c.warningText,
                ),
                const SizedBox(width: Space.s1),
                Expanded(
                  child: Text(
                    verified ? 'Adresse vérifiée' : 'Adresse pas encore vérifiée',
                    style: AppText.bodySm.copyWith(color: verified ? c.successText : c.warningText),
                  ),
                ),
              ],
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: Space.s3),
            FormMessage(message),
          ],
          const SizedBox(height: Space.s4),
          AppButton(key: const Key('profile.save'), label: 'Enregistrer', onPressed: _save),
          if (email != null && !verified) ...[
            const SizedBox(height: Space.s6),
            Text('VÉRIFIER MON ADRESSE', style: AppText.overline.copyWith(color: c.inkMuted)),
            const SizedBox(height: Space.s2),
            if (_sent case final sent?) ...[
              Text(
                'Code envoyé à ${sent.sentTo}. Il expire dans 15 minutes.',
                style: AppText.bodySm.copyWith(color: c.inkMuted),
              ),
              // Mode démo : aucun e-mail ne part, l'API renvoie le code (jamais en vrai).
              if (sent.demoCode case final code?) ...[
                const SizedBox(height: Space.s2),
                FormMessage(
                  'Mode démo : aucun e-mail n’est envoyé. Code : $code',
                  tone: FormMessageTone.info,
                ),
              ],
              const SizedBox(height: Space.s3),
              AppTextField(
                key: const Key('profile.code'),
                label: 'Code reçu',
                controller: _code,
                error: _codeError,
                keyboardType: TextInputType.number,
                mono: true,
                onChanged: (_) => setState(() => _codeError = null),
              ),
              const SizedBox(height: Space.s3),
              AppButton(
                key: const Key('profile.confirm'),
                label: 'Vérifier l’adresse',
                onPressed: _confirm,
              ),
              AppButton(
                label: 'Renvoyer un code',
                variant: ButtonVariant.ghost,
                onPressed: _sendCode,
              ),
            ] else
              AppButton(
                key: const Key('profile.sendCode'),
                label: 'Recevoir un code par e-mail',
                variant: ButtonVariant.secondary,
                onPressed: _sendCode,
              ),
          ],
        ],
      ),
    );
  }
}
