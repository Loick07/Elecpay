import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/phone.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_message.dart';
import '../legal/legal_screen.dart';
import 'models/auth_models.dart';
import 'password_rules.dart';
import 'retry_lock.dart';
import 'validation.dart';

/// Inscription (écran 3, maquette `Inscription.dc.html`) : nom, téléphone, e-mail facultatif,
/// mot de passe (règles cochées pendant la saisie), conditions acceptées (case obligatoire).
///
/// Réussite : la session s'ouvre et la garde mène à l'accueil, où l'on ajoute son premier compteur.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  /// Texte d'introduction : il dit la même chose que l'accueil (« Ajoutez votre premier compteur »).
  static const intro = 'Vous ajouterez votre compteur E²C juste après, depuis l’accueil.';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _lock = RetryLock();
  bool _accepted = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _termsError;
  String? _message;
  String? _reference;

  @override
  void initState() {
    super.initState();
    _lock.addListener(() {
      if (!mounted) return;
      setState(() {
        if (!_lock.locked) _message = null;
      });
    });
  }

  @override
  void dispose() {
    _lock.dispose();
    for (final controller in [_name, _phone, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_lock.locked) return;
    setState(() {
      _nameError = fullNameError(_name.text);
      _phoneError = phoneError(_phone.text);
      _emailError = emailError(_email.text);
      _passwordError = passwordError(_password.text);
      _termsError = _accepted
          ? null
          : 'Acceptez les conditions d’utilisation et la politique de confidentialité pour '
                'créer votre compte.';
      _message = null;
      _reference = null;
    });
    if ([_nameError, _phoneError, _emailError, _passwordError, _termsError].any((e) => e != null)) {
      return;
    }

    try {
      await ref
          .read(sessionManagerProvider)
          .register(
            RegisterRequest(
              fullName: normalizeFullName(_name.text),
              phone: normalizeCongoPhone(_phone.text),
              email: normalizeEmail(_email.text),
              password: _password.text,
            ),
          );
      TextInput.finishAutofillContext();
      // La garde de navigation mène à l'accueil (session ouverte).
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
    }
  }

  void _showFailure(ApiFailure failure) {
    setState(() {
      switch (failure) {
        case ApiRejected(code: 'PHONE_ALREADY_USED'):
          _phoneError = failure.message;
        case ApiRejected(code: 'EMAIL_ALREADY_USED'):
          _emailError = failure.message;
        case TooManyRequests():
          _message = 'Trop de tentatives.';
        case InvalidFields(:final fields):
          const refused = 'Valeur refusée par ElecPay : vérifiez ce champ.';
          if (fields.containsKey('full_name')) _nameError = refused;
          if (fields.containsKey('phone')) _phoneError = refused;
          if (fields.containsKey('email')) _emailError = refused;
          if (fields.containsKey('password')) _passwordError = refused;
          _message = failure.message;
        default:
          _message = failure.message;
          _reference = failure.reference;
      }
    });
    if (failure is TooManyRequests) _lock.lockFor(failure.retryAfter);
  }

  void _clear(void Function() reset) => setState(reset);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          // Formulaire : tout est construit (pas de ListView paresseux qui jetterait un champ
          // sorti de l'écran avec son focus).
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
                    tooltip: 'Retour à la connexion',
                    icon: AppIcon(AppIcons.back, size: 22, color: c.ink),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Créer un compte',
                    style: AppText.h1.copyWith(color: c.ink, fontSize: 28, height: 1.29),
                  ),
                ),
                const SizedBox(height: 6),
                Text(RegisterScreen.intro, style: AppText.body.copyWith(color: c.inkMuted)),
                const SizedBox(height: Space.s6),
                AppTextField(
                  label: 'Nom et prénom',
                  controller: _name,
                  error: _nameError,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _nameError == null ? null : _clear(() => _nameError = null),
                ),
                const SizedBox(height: Space.s4),
                PhoneField(
                  controller: _phone,
                  error: _phoneError,
                  helper: 'Il servira à vous connecter et à recevoir vos alertes.',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _phoneError == null ? null : _clear(() => _phoneError = null),
                ),
                const SizedBox(height: Space.s4),
                AppTextField(
                  label: 'E-mail (facultatif)',
                  controller: _email,
                  error: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _emailError == null ? null : _clear(() => _emailError = null),
                ),
                const SizedBox(height: Space.s4),
                AppTextField(
                  label: 'Mot de passe',
                  controller: _password,
                  password: true,
                  error: _passwordError,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _passwordError = null),
                ),
                const SizedBox(height: Space.s2),
                PasswordRules(_password.text),
                const SizedBox(height: Space.s4),
                _Terms(
                  accepted: _accepted,
                  error: _termsError,
                  onChanged: (value) => setState(() {
                    _accepted = value;
                    if (value) _termsError = null;
                  }),
                ),
                const SizedBox(height: Space.s5),
                if (_message != null) ...[
                  FormMessage(_message!, reference: _reference),
                  const SizedBox(height: Space.s3),
                ],
                AppButton(
                  label: _lock.locked ? _lock.label : 'Créer mon compte',
                  loadingLabel: 'Création du compte…',
                  onPressed: _lock.locked ? null : _submit,
                ),
                const SizedBox(height: Space.s2),
                Center(
                  child: TextButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    child: Text.rich(
                      TextSpan(
                        text: 'Déjà inscrit ? ',
                        style: AppText.bodySm.copyWith(color: c.inkMuted),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: TextStyle(color: c.voltText, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Case « J'accepte… » (obligatoire) et liens vers les deux documents (provisoires).
class _Terms extends StatelessWidget {
  const _Terms({required this.accepted, required this.error, required this.onChanged});

  final bool accepted;
  final String? error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final link = AppText.bodySm.copyWith(color: c.voltText, fontWeight: FontWeight.w500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: accepted,
                    onChanged: (value) => onChanged(value ?? false),
                    activeColor: c.volt,
                    checkColor: c.onVolt,
                    side: BorderSide(color: error == null ? c.inkMuted : c.error, width: 1.5),
                  ),
                  Expanded(
                    child: Text(
                      'J’accepte les conditions d’utilisation et la politique de confidentialité.',
                      style: AppText.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          children: [
            for (final document in LegalDocument.values)
              TextButton(
                onPressed: () => context.push(document.path),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text('Lire : ${document.title.toLowerCase()}', style: link),
              ),
          ],
        ),
        if (error != null) Text(error!, style: AppText.bodySm.copyWith(color: c.errorText)),
      ],
    );
  }
}
