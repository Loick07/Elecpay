import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_health.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/demo_badge.dart';
import '../diagnostic/diagnostic_access.dart';

/// Écran de démarrage PROVISOIRE (F0) : vérifie que l'API répond (`/health`) et affiche le badge
/// « Mode démo ». Il deviendra le Splash de la maquette (écran 1) en F3.
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final health = ref.watch(apiHealthProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.s6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ElecPay', style: AppText.display.copyWith(color: c.ink)),
              const SizedBox(height: Space.s8),
              switch (health) {
                AsyncData(value: final ApiReachable api) => _Reachable(api: api),
                AsyncData(value: final ApiUnreachable api) => _Unreachable(address: api.address),
                AsyncError() => const _Unreachable(address: null),
                _ => Text('Connexion à ElecPay…', style: AppText.body.copyWith(color: c.inkMuted)),
              },
              if (diagnosticsEnabled) ...[
                const SizedBox(height: Space.s8),
                TextButton(
                  onPressed: () => context.push('/diagnostic'),
                  child: Text(
                    'Diagnostic',
                    style: AppText.bodyStrong.copyWith(color: c.currentText),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/catalogue'),
                  child: Text(
                    'Catalogue',
                    style: AppText.bodyStrong.copyWith(color: c.currentText),
                  ),
                ),
              ],
              if (kDebugMode)
                TextButton(
                  onPressed: () => context.push('/charte'),
                  child: Text(
                    'Voir la charte',
                    style: AppText.bodyStrong.copyWith(color: c.currentText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reachable extends StatelessWidget {
  const _Reachable({required this.api});

  final ApiReachable api;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!api.databaseOk) {
      return Text(
        'Le service ElecPay est momentanément indisponible. Réessayez dans un instant.',
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: c.errorText),
      );
    }
    return Column(
      children: [
        Text('API joignable', style: AppText.bodyStrong.copyWith(color: c.success)),
        if (api.demoMode) ...[const SizedBox(height: Space.s3), const DemoBadge()],
      ],
    );
  }
}

class _Unreachable extends ConsumerWidget {
  const _Unreachable({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Column(
      children: [
        Text(
          'Impossible de joindre ElecPay. Vérifiez votre connexion puis réessayez.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: c.ink),
        ),
        if (kDebugMode && address != null) ...[
          const SizedBox(height: Space.s3),
          Text(
            'Développement : API attendue à $address. En USB, lancez « adb reverse tcp:8000 '
            'tcp:8000 » ; en Wi-Fi, vérifiez l’IP du PC et le pare-feu.',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: c.inkMuted),
          ),
        ],
        const SizedBox(height: Space.s4),
        FilledButton(
          onPressed: () => ref.invalidate(apiHealthProvider),
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}
