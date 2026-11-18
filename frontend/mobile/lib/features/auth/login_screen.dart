import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/format/phone.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_message.dart';
import '../diagnostic/diagnostic_access.dart';
import 'models/auth_models.dart';

/// Écran de connexion (écran 2, maquette `Connexion.dc.html`) : numéro +242 et mot de passe.
///
/// - vérification AVANT l'envoi (mêmes messages que le backend) ;
/// - réussite : la garde de navigation mène à l'accueil (session ouverte) ;
/// - trop de tentatives (429) : bouton désactivé avec un compte à rebours ;
/// - compte de l'équipe (code 2FA demandé) : aucune session, renvoi vers le back-office.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _phoneError;
  String? _passwordError;
  String? _message;
  String? _reference;
  int _lockSeconds = 0;
  Timer? _lockTimer;

  /// Délai d'attente quand l'API ne précise pas le sien (429 sans `retry_after_seconds`).
  static const defaultLock = Duration(seconds: 60);

  @override
  void dispose() {
    _lockTimer?.cancel();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _locked => _lockSeconds > 0;

  Future<void> _submit() async {
    if (_locked) return;
    final phoneProblem = phoneError(_phone.text);
    final passwordProblem = _password.text.isEmpty ? 'Saisissez votre mot de passe.' : null;
    setState(() {
      _phoneError = phoneProblem;
      _passwordError = passwordProblem;
      _message = null;
      _reference = null;
    });
    if (phoneProblem != null || passwordProblem != null) return;

    try {
      final result = await ref
          .read(sessionManagerProvider)
          .login(LoginRequest(phone: normalizeCongoPhone(_phone.text), password: _password.text));
      if (!mounted) return;
      switch (result) {
        case LoginSucceeded():
          // Le gestionnaire de mots de passe d'Android peut proposer d'enregistrer.
          TextInput.finishAutofillContext();
        // La garde de navigation mène à l'accueil.
        case LoginNeedsTwoFactor():
          setState(
            () => _message =
                'Ce compte est réservé à l’équipe ElecPay : connectez-vous depuis le '
                'back-office.',
          );
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  void _showFailure(ApiFailure failure) {
    setState(() {
      _reference = failure.reference;
      _message = switch (failure) {
        // Le bouton donne déjà le temps exact (« Réessayer dans 2:05 »).
        TooManyRequests() => 'Trop de tentatives.',
        ApiRejected(code: 'ACCOUNT_DISABLED') =>
          '${failure.message} Contactez l’assistance ElecPay.',
        InvalidFields() => 'Vérifiez le numéro et le mot de passe.',
        _ => failure.message,
      };
      // Identifiants incorrects, trop de tentatives : pas de référence utile à l'utilisateur.
      if (failure is ApiRejected && failure.statusCode != 403) _reference = null;
      // Identifiants incorrects : on garde le numéro, on vide le mot de passe (à ressaisir).
      if (failure case ApiRejected(code: 'INVALID_CREDENTIALS')) _password.clear();
    });
    if (failure is TooManyRequests) _lockFor(failure.retryAfter ?? defaultLock);
  }

  void _lockFor(Duration wait) {
    _lockTimer?.cancel();
    setState(() => _lockSeconds = wait.inSeconds.clamp(1, 24 * 3600));
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _lockSeconds--;
        if (_lockSeconds <= 0) {
          timer.cancel();
          _message = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg,
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.9,
            colors: [c.current.withValues(alpha: 0.22), c.bg],
          ),
        ),
        child: SafeArea(
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
                        const SizedBox(height: Space.s10),
                        const _Brand(),
                        const SizedBox(height: Space.s10),
                        Semantics(
                          header: true,
                          child: Text(
                            'Connexion',
                            style: AppText.h1.copyWith(color: c.ink, fontSize: 28, height: 1.29),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connectez-vous avec votre numéro de téléphone.',
                          style: AppText.body.copyWith(color: c.inkMuted),
                        ),
                        const SizedBox(height: Space.s8),
                        PhoneField(
                          controller: _phone,
                          error: _phoneError,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_phoneError != null) setState(() => _phoneError = null);
                          },
                        ),
                        const SizedBox(height: Space.s4),
                        AppTextField(
                          label: 'Mot de passe',
                          controller: _password,
                          password: true,
                          error: _passwordError,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) {
                            if (_passwordError != null) setState(() => _passwordError = null);
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(Routes.forgotPassword),
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppText.bodySm.copyWith(
                                color: c.voltText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_message != null) ...[
                          FormMessage(_message!, reference: _reference),
                          const SizedBox(height: Space.s3),
                        ],
                        AppButton(
                          label: _locked
                              ? 'Réessayer dans ${formatCountdown(Duration(seconds: _lockSeconds))}'
                              : 'Se connecter',
                          loadingLabel: 'Connexion…',
                          onPressed: _locked ? null : _submit,
                        ),
                        const Spacer(),
                        const SizedBox(height: Space.s8),
                        Text(
                          'Pas encore de compte ?',
                          textAlign: TextAlign.center,
                          style: AppText.bodySm.copyWith(color: c.inkMuted),
                        ),
                        const SizedBox(height: Space.s4),
                        AppButton(
                          label: 'Créer un compte',
                          variant: ButtonVariant.secondary,
                          onPressed: () => context.push(Routes.register),
                        ),
                        if (diagnosticsEnabled) const _DevLinks(),
                        const SizedBox(height: Space.s8),
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
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.volt,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: AppIcon(AppIcons.energy, size: 22, color: c.onVolt),
        ),
        const SizedBox(width: 10),
        Text(
          'ElecPay',
          style: AppText.h2.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Debug et profile : accès aux pages Diagnostic et Catalogue (retirées en release).
class _DevLinks extends StatelessWidget {
  const _DevLinks();

  @override
  Widget build(BuildContext context) {
    final style = AppText.bodySm.copyWith(color: context.colors.currentText);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.push('/diagnostic'),
          child: Text('Diagnostic', style: style),
        ),
        TextButton(
          onPressed: () => context.push('/catalogue'),
          child: Text('Catalogue', style: style),
        ),
      ],
    );
  }
}
