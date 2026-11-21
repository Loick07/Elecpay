import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_message.dart';
import '../auth/models/auth_models.dart';
import '../auth/password_rules.dart';
import '../auth/validation.dart';
import '../households/manage_sheets.dart' show confirmAction;

/// « Mot de passe et sécurité » (écran 14, F9.3) : changer de mot de passe (les autres appareils
/// sont déconnectés, celui-ci reçoit de nouveaux jetons) ; déconnecter TOUS les appareils.
///
/// L'API `POST /auth/logout-all` révoque TOUTES les sessions, celle-ci comprise : le bouton le dit,
/// et déconnecte cet appareil tout de suite (sinon il le serait sans prévenir 15 minutes plus tard).
/// Pour déconnecter seulement les autres appareils : changer de mot de passe.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _currentError;
  String? _nextError;
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    setState(() {
      _currentError = _current.text.isEmpty ? 'Saisissez votre mot de passe actuel.' : null;
      _nextError = passwordError(_next.text);
      _message = null;
    });
    if (_currentError != null || _nextError != null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tokens = await ref
          .read(authenticatedApiProvider)
          .postObject(
            '/me/password',
            TokenResponse.fromJson,
            body: ChangePasswordRequest(currentPassword: _current.text, newPassword: _next.text),
          );
      // Nouveaux jetons enregistrés AVANT tout : les anciens ne valent plus rien.
      await ref.read(sessionManagerProvider).signIn(tokens);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      setState(() {});
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Mot de passe changé. Vos autres appareils sont déconnectés.'),
          ),
        );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        switch (failure) {
          case ApiRejected(code: 'WRONG_CURRENT_PASSWORD'):
            _currentError = failure.message;
          case ApiRejected(code: 'SAME_PASSWORD'):
            _nextError = failure.message;
          case InvalidFields(:final fields) when fields.containsKey('new_password'):
            _nextError = 'Mot de passe refusé par ElecPay : vérifiez les règles.';
          case TooManyRequests():
            _message = 'Trop de tentatives. Réessayez dans un moment.';
          default:
            _message = failure.message;
        }
      });
    }
  }

  Future<void> _logoutEverywhere() async {
    final ok = await confirmAction(
      context,
      title: 'Déconnecter tous vos appareils ?',
      message:
          'Tous les téléphones connectés à votre compte, y compris celui-ci, devront se '
          'reconnecter avec votre mot de passe.',
      confirmLabel: 'Tout déconnecter',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authenticatedApiProvider)
          .postObject('/auth/logout-all', LogoutAllResponse.fromJson);
      // Cette session est révoquée elle aussi : on la termine tout de suite (écran de connexion).
      await ref.read(sessionManagerProvider).logout();
    } on ApiFailure catch (failure) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Mot de passe et sécurité'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s8),
          child: Column(
            key: const Key('security.form'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CHANGER DE MOT DE PASSE', style: AppText.overline.copyWith(color: c.inkMuted)),
              const SizedBox(height: Space.s3),
              AppTextField(
                key: const Key('security.current'),
                label: 'Mot de passe actuel',
                controller: _current,
                error: _currentError,
                password: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => setState(() => _currentError = null),
              ),
              const SizedBox(height: Space.s3),
              AppTextField(
                key: const Key('security.next'),
                label: 'Nouveau mot de passe',
                controller: _next,
                error: _nextError,
                password: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() => _nextError = null),
              ),
              const SizedBox(height: Space.s2),
              PasswordRules(_next.text),
              if (_message case final message?) ...[
                const SizedBox(height: Space.s3),
                FormMessage(message),
              ],
              const SizedBox(height: Space.s4),
              AppButton(
                key: const Key('security.change'),
                label: 'Changer le mot de passe',
                onPressed: _change,
              ),
              const SizedBox(height: Space.s2),
              Text(
                'Vos autres appareils seront déconnectés ; celui-ci reste connecté.',
                style: AppText.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s6),
              Text('MES APPAREILS', style: AppText.overline.copyWith(color: c.inkMuted)),
              const SizedBox(height: Space.s2),
              Text(
                'Un téléphone perdu ou prêté ? Déconnectez tous les appareils connectés à votre '
                'compte, celui-ci compris. Pour ne déconnecter que les autres, changez plutôt de '
                'mot de passe.',
                style: AppText.bodySm.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Space.s3),
              AppButton(
                key: const Key('security.logoutAll'),
                label: 'Déconnecter tous mes appareils',
                variant: ButtonVariant.danger,
                // Sans attendre la confirmation : le bouton ne tourne pas derrière la feuille.
                onPressed: () => unawaited(_logoutEverywhere()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
