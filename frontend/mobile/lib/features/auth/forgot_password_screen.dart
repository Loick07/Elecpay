import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/phone.dart';
import '../../core/format/typography.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_message.dart';
import 'code_field.dart';
import 'models/auth_models.dart';
import 'password_rules.dart';
import 'retry_lock.dart';
import 'validation.dart';

enum ForgotStep { phone, code, done }

/// Mot de passe oublié (écran 4, maquette `MotDePasse.dc.html`), en 3 étapes :
/// 1. le numéro → `POST /auth/password/forgot` ;
/// 2. le code reçu par SMS + le nouveau mot de passe → `POST /auth/password/reset` ;
/// 3. « Mot de passe modifié » → se reconnecter (l'API a fermé toutes les sessions du compte).
///
/// Le parcours est le même que le numéro ait un compte ou non (l'API répond pareil) : on passe
/// toujours à l'étape 2. Le code n'est affiché que si l'API le donne (`demo_code`, mode démo).
/// Un nouveau code ne peut être demandé que 60 s après le précédent.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  /// Délai avant de pouvoir redemander un code.
  static const resendDelay = Duration(seconds: 60);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  /// « Suivant » depuis le code → ce champ (et pas « Renvoyer le code »).
  final _passwordFocus = FocusNode();

  /// Trop de tentatives (429) sur le bouton principal de l'étape.
  final _lock = RetryLock();

  /// Délai avant un nouveau code (60 s, ou le délai d'un 429 sur « Renvoyer le code »).
  final _resend = RetryLock(prefix: 'Renvoyer le code dans');

  ForgotStep _step = ForgotStep.phone;
  String _sentTo = '';
  String? _demoCode;
  String? _phoneError;
  String? _codeError;
  String? _passwordError;
  String? _message;
  FormMessageTone _tone = FormMessageTone.error;
  String? _reference;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _lock.addListener(() {
      if (!mounted) return;
      setState(() {
        if (!_lock.locked && _message == 'Trop de tentatives.') _message = null;
      });
    });
    _resend.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lock.dispose();
    _resend.dispose();
    for (final controller in [_phone, _code, _password]) {
      controller.dispose();
    }
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearMessage() {
    _message = null;
    _reference = null;
    _tone = FormMessageTone.error;
  }

  /// Étape 1 (et « Renvoyer le code ») : demande d'un code pour le numéro saisi.
  Future<void> _sendCode() async {
    if (_lock.locked || _resend.locked) return;
    final problem = phoneError(_phone.text);
    setState(() {
      _phoneError = problem;
      _clearMessage();
    });
    if (problem != null) return;
    final phone = normalizeCongoPhone(_phone.text);
    try {
      final response = await ref
          .read(sessionManagerProvider)
          .requestPasswordReset(ForgotPasswordRequest(phone: phone));
      if (!mounted) return;
      setState(() {
        _step = ForgotStep.code;
        _sentTo = phone;
        _demoCode = response.demoCode;
        _code.clear();
        _codeError = null;
      });
      _resend.lockFor(ForgotPasswordScreen.resendDelay);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure) {
          case TooManyRequests():
            _message = 'Trop de tentatives.';
          case InvalidFields():
            _phoneError = 'Valeur refusée par ElecPay : vérifiez ce numéro.';
          default:
            _message = failure.message;
            _reference = failure.reference;
        }
      });
      if (failure is TooManyRequests) {
        // Étape 2 : seul « Renvoyer le code » attend ; étape 1 : le bouton principal.
        (_step == ForgotStep.code ? _resend : _lock).lockFor(failure.retryAfter);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await _sendCode();
      if (mounted && _message == null) {
        setState(() {
          _tone = FormMessageTone.info;
          _message = 'Nouveau code demandé. L’ancien code ne fonctionne plus.';
        });
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// Étape 2 : nouveau mot de passe avec le code.
  Future<void> _reset() async {
    if (_lock.locked) return;
    final code = _code.text;
    setState(() {
      _codeError = RegExp(r'^\d{6}$').hasMatch(code)
          ? null
          : 'Saisissez les ${CodeField.length} chiffres du code reçu.';
      _passwordError = passwordError(_password.text);
      _clearMessage();
    });
    if (_codeError != null || _passwordError != null) return;
    try {
      await ref
          .read(sessionManagerProvider)
          .resetPassword(
            ResetPasswordRequest(phone: _sentTo, code: code, newPassword: _password.text),
          );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      setState(() => _step = ForgotStep.done);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure) {
          // Code faux, expiré, déjà utilisé ou trop d'essais : le message de l'API invite à
          // demander un nouveau code (« Renvoyer le code », juste dessous).
          case ApiRejected(code: 'RESET_CODE_INVALID'):
            _codeError = failure.message;
            _code.clear();
          case TooManyRequests():
            _message = 'Trop de tentatives.';
          case InvalidFields(:final fields):
            const refused = 'Valeur refusée par ElecPay : vérifiez ce champ.';
            if (fields.containsKey('code')) _codeError = refused;
            if (fields.containsKey('new_password')) _passwordError = refused;
            _message = failure.message;
          default:
            _message = failure.message;
            _reference = failure.reference;
        }
      });
      if (failure is TooManyRequests) _lock.lockFor(failure.retryAfter);
    }
  }

  void _back() {
    if (_step == ForgotStep.code) {
      setState(() {
        _step = ForgotStep.phone;
        _clearMessage();
      });
    } else if (_step == ForgotStep.done || !context.canPop()) {
      context.go(Routes.login);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stepNumber = _step.index + 1;
    return PopScope(
      // Retour système à l'étape 2 : revenir au numéro, pas quitter l'écran.
      canPop: _step == ForgotStep.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Space.s4),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: Space.s2),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _back,
                              tooltip: _step == ForgotStep.code
                                  ? 'Retour : modifier le numéro'
                                  : 'Retour à la connexion',
                              icon: AppIcon(AppIcons.back, size: 22, color: c.ink),
                            ),
                            const SizedBox(width: Space.s2),
                            Expanded(
                              child: Text(
                                'Étape $stepNumber sur 3',
                                textAlign: TextAlign.end,
                                style: AppText.bodySm.copyWith(
                                  color: c.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.s2),
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              for (var i = 1; i <= 3; i++) ...[
                                if (i > 1) const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i <= stepNumber ? c.volt : c.surface3,
                                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ...switch (_step) {
                          ForgotStep.phone => _phoneStep(c),
                          ForgotStep.code => _codeStep(c),
                          ForgotStep.done => _doneStep(c),
                        },
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(ElecPayColors c, String text) => Semantics(
    header: true,
    child: Text(text, style: AppText.h1.copyWith(color: c.ink, fontSize: 28, height: 1.29)),
  );

  List<Widget> _messageBlock() => [
    if (_message != null) ...[
      FormMessage(_message!, tone: _tone, reference: _reference),
      const SizedBox(height: Space.s3),
    ],
  ];

  List<Widget> _phoneStep(ElecPayColors c) => [
    const SizedBox(height: Space.s6),
    _title(c, 'Mot de passe oublié'),
    const SizedBox(height: 6),
    Text(
      'Saisissez votre numéro. Nous vous envoyons un code à 6 chiffres par SMS.',
      style: AppText.body.copyWith(color: c.inkMuted),
    ),
    const SizedBox(height: Space.s6),
    PhoneField(
      controller: _phone,
      error: _phoneError,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _sendCode(),
      onChanged: (_) {
        if (_phoneError != null) setState(() => _phoneError = null);
      },
    ),
    const Spacer(),
    const SizedBox(height: Space.s6),
    ..._messageBlock(),
    AppButton(
      label: _lock.locked
          ? _lock.label
          : (_resend.locked ? 'Nouveau code dans ${_resend.remaining}' : 'Envoyer le code'),
      loadingLabel: 'Envoi du code…',
      onPressed: _lock.locked || _resend.locked ? null : _sendCode,
    ),
  ];

  List<Widget> _codeStep(ElecPayColors c) => [
    const SizedBox(height: Space.s6),
    _title(c, 'Nouveau mot de passe'),
    const SizedBox(height: 6),
    // Même texte pour tous les numéros : on ne dit pas si le compte existe.
    Text.rich(
      TextSpan(
        text: 'Si ce numéro correspond à un compte, un code vient d’être envoyé par SMS au ',
        children: [
          TextSpan(
            text: formatPhone(_sentTo),
            style: TextStyle(color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      style: AppText.body.copyWith(color: c.inkMuted),
    ),
    if (_demoCode != null) ...[const SizedBox(height: Space.s5), _DemoCodeNotice(_demoCode!)],
    const SizedBox(height: Space.s5),
    CodeField(
      controller: _code,
      error: _codeError,
      onEditingComplete: _passwordFocus.requestFocus,
      onChanged: (_) {
        if (_codeError != null) setState(() => _codeError = null);
      },
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _resend.locked || _resending ? null : _resendCode,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          foregroundColor: c.voltText,
          disabledForegroundColor: c.inkMuted,
        ),
        child: Text(
          _resend.locked ? _resend.label : 'Renvoyer le code',
          style: AppText.bodySm.copyWith(
            fontWeight: _resend.locked ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
      ),
    ),
    const SizedBox(height: Space.s3),
    AppTextField(
      label: 'Nouveau mot de passe',
      controller: _password,
      focusNode: _passwordFocus,
      password: true,
      error: _passwordError,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _reset(),
      onChanged: (_) => setState(() => _passwordError = null),
    ),
    const SizedBox(height: Space.s2),
    PasswordRules(_password.text),
    const Spacer(),
    const SizedBox(height: Space.s6),
    ..._messageBlock(),
    AppButton(
      label: _lock.locked ? _lock.label : 'Changer le mot de passe',
      loadingLabel: 'Changement en cours…',
      onPressed: _lock.locked ? null : _reset,
    ),
  ];

  List<Widget> _doneStep(ElecPayColors c) => [
    const SizedBox(height: 96),
    Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
        child: AppIcon(AppIcons.check, size: 34, color: c.success),
      ),
    ),
    const SizedBox(height: Space.s4),
    Semantics(
      header: true,
      child: Text(
        'Mot de passe modifié',
        textAlign: TextAlign.center,
        style: AppText.h1.copyWith(color: c.ink, fontSize: 24, height: 1.33),
      ),
    ),
    const SizedBox(height: Space.s3),
    Text(
      'Par sécurité, vous avez été déconnecté de vos autres appareils.',
      textAlign: TextAlign.center,
      style: AppText.body.copyWith(color: c.inkMuted),
    ),
    const Spacer(),
    const SizedBox(height: Space.s6),
    AppButton(label: 'Se connecter', onPressed: () => context.go(Routes.login)),
  ];
}

/// Mode démo : le code est affiché à l'écran (aucun SMS n'est envoyé).
class _DemoCodeNotice extends StatelessWidget {
  const _DemoCodeNotice(this.code);

  final String code;

  /// « 482913 » → « 482 913 » (espace insécable).
  String get _grouped =>
      code.length == 6 ? '${code.substring(0, 3)}$groupSpace${code.substring(3)}' : code;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s3),
        decoration: BoxDecoration(
          color: c.currentSoft,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
          border: Border.all(color: c.currentText),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.info, size: 18, color: c.currentText),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Mode démo : aucun SMS n’est envoyé. Votre code est ',
                  children: [
                    TextSpan(
                      text: _grouped,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06 * 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: AppText.bodySm.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
