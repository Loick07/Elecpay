import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/config/app_config.dart';
import '../../core/format/dates.dart';
import '../../core/network/api_failure.dart';
import '../../core/session/session_manager.dart';
import '../../core/session/session_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/glass.dart';
import '../auth/models/auth_models.dart';
import 'diagnostic_access.dart';

/// Page Diagnostic (debug et profile seulement, voir [diagnosticsEnabled]) : vérifie sur le téléphone
/// la session, le rafraîchissement du jeton et le mode hors ligne, avant les vrais écrans (F3).
class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  final _phone = TextEditingController(text: '+242060000101');
  final _password = TextEditingController(text: 'Demo2026!');
  final _log = <String>[];
  bool _busy = false;
  DateTime? _accessExpiresAt;

  SessionManager get _session => ref.read(sessionManagerProvider);

  @override
  void initState() {
    super.initState();
    // Lit la session enregistrée dès l'ouverture (sinon « Session : lecture… » restait affiché).
    _session.currentTokens().then((tokens) {
      if (mounted) setState(() => _accessExpiresAt = tokens?.accessExpiresAt);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Lance une action, note son résultat (ou son échec, avec la référence) en tête du journal.
  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    String line;
    try {
      line = await action();
    } on ApiFailure catch (failure) {
      line =
          '${failure.message}${failure.reference == null ? '' : ' (Référence : ${failure.reference})'}';
    }
    final tokens = await _session.currentTokens();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _accessExpiresAt = tokens?.accessExpiresAt;
      _log.insert(0, line);
    });
  }

  Future<String> _login() async {
    final result = await _session.login(
      LoginRequest(phone: _phone.text.trim(), password: _password.text),
    );
    return switch (result) {
      LoginSucceeded(:final tokens) => 'Connecté : ${tokens.user.fullName}',
      LoginNeedsTwoFactor() =>
        'Compte de l’équipe : code 2FA demandé (aucune session dans l’application client)',
    };
  }

  Future<String> _readProfile() async {
    final result = await ref.read(cachedApiProvider).get('/me', UserPublic.fromJson);
    return switch (result) {
      FreshData(:final data) => 'Profil : ${data.fullName} — donnée fraîche',
      CachedData(:final data, :final label) => 'Profil : ${data.fullName} — $label',
    };
  }

  Future<String> _parallelReads() async {
    final before = _session.refreshCount;
    final api = ref.read(cachedApiProvider);
    final results = await Future.wait([
      for (var i = 0; i < 5; i++) api.get('/me', UserPublic.fromJson),
    ]);
    final refreshes = _session.refreshCount - before;
    return '${results.length} lectures simultanées réussies, '
        '$refreshes rafraîchissement${refreshes > 1 ? 's' : ''} de jeton';
  }

  Future<String> _logout() async {
    await _session.logout();
    return 'Déconnecté : jetons et cache effacés';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = ref.watch(sessionStateProvider);
    final config = ref.watch(appConfigProvider);
    final connected = session is SessionActive;

    return Scaffold(
      // Titre court : « Diagnostic (développement) » était coupé sur l'itel A05s (jalon F1).
      appBar: AppBar(title: const Text('Diagnostic')),
      body: Semantics(
        // Marque cherchée dans l'APK par tool/apk_check.dart : absente en release.
        identifier: diagnosticMarker,
        child: ListView(
          padding: const EdgeInsets.all(Space.s4),
          children: [
            const _Line('Version', kProfileMode ? 'profile' : 'debug'),
            _Line('API', config.apiRoot),
            _Line('Session', switch (session) {
              SessionUnknown() => 'lecture…',
              SessionActive(:final userId) => 'connectée (utilisateur $userId)',
              SessionEnded(:final reason) => switch (reason) {
                SessionEndReason.none => 'aucune',
                SessionEndReason.loggedOut => 'déconnectée',
                SessionEndReason.expired => 'expirée',
              },
            }),
            if (connected && _accessExpiresAt != null)
              _Line('Jeton d’accès', 'valable jusqu’au ${_formatSeconds(_accessExpiresAt!)}'),
            _Line('Rafraîchissements', '${_session.refreshCount}'),
            // Jalon F3 : comparer la fluidité de l'itel avec et sans flou.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Effet verre (flou)', style: AppText.bodyStrong.copyWith(color: c.ink)),
              subtitle: Text(
                ref.watch(glassModeProvider) == GlassMode.blur
                    ? 'Flou d’arrière-plan (barre du bas, feuilles)'
                    : 'Sans flou : fond opaque',
                style: AppText.bodySm.copyWith(color: c.inkMuted),
              ),
              value: ref.watch(glassModeProvider) == GlassMode.blur,
              onChanged: (blur) => ref
                  .read(glassModeProvider.notifier)
                  .set(blur ? GlassMode.blur : GlassMode.opaque),
            ),
            const SizedBox(height: Space.s4),
            if (!connected) ...[
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Numéro (compte de démo)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: Space.s3),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              const SizedBox(height: Space.s3),
              FilledButton(
                onPressed: _busy ? null : () => _run(_login),
                child: const Text('Se connecter'),
              ),
            ],
            const SizedBox(height: Space.s3),
            OutlinedButton(
              onPressed: _busy || !connected ? null : () => _run(_readProfile),
              child: const Text('Lire mon profil'),
            ),
            const SizedBox(height: Space.s3),
            OutlinedButton(
              onPressed: _busy || !connected ? null : () => _run(_parallelReads),
              child: const Text('5 lectures en même temps'),
            ),
            const SizedBox(height: Space.s3),
            OutlinedButton(
              onPressed: _busy || !connected ? null : () => _run(_logout),
              child: const Text('Se déconnecter'),
            ),
            const SizedBox(height: Space.s6),
            Text('Journal', style: AppText.bodyStrong.copyWith(color: c.ink)),
            const SizedBox(height: Space.s2),
            for (final line in _log)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Text(line, style: AppText.bodySm.copyWith(color: c.inkMuted)),
              ),
          ],
        ),
      ),
    );
  }

  /// « 16 nov. à 13:20:45 » : la seconde compte avec des jetons d'une minute.
  static String _formatSeconds(DateTime moment) {
    final seconds = toBrazzaville(moment).second.toString().padLeft(2, '0');
    return '${formatDateTime(moment, now: DateTime.now())}:$seconds';
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: AppText.bodyStrong.copyWith(color: c.ink),
            ),
            TextSpan(
              text: value,
              style: AppText.body.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
