import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/state_block.dart';
import 'startup_decision.dart';

/// Splash (écran 1, maquette `Splash.dc.html`) : logo, accroche, barre de chargement, badge Mode
/// démo. 2 s au plus, puis l'accueil (session enregistrée) ou la connexion ; sans session et sans
/// API : bloc « Hors connexion » avec Réessayer.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(startupDecisionProvider, (previous, next) {
      final decision = next.value;
      final target = switch (decision) {
        GoHome() => Routes.home,
        GoLogin() => Routes.login,
        _ => null,
      };
      if (target != null) context.go(target);
    });

    final c = context.colors;
    final decision = ref.watch(startupDecisionProvider).value;
    // Affiché tant qu'on ne sait pas (dernière valeur connue, puis réponse de l'API).
    final demo = ref.watch(demoModeProvider).showBadge;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg,
          gradient: RadialGradient(
            center: const Alignment(0, -0.16),
            radius: 0.8,
            colors: [c.current.withValues(alpha: 0.28), c.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(),
                  const SizedBox(height: Space.s5),
                  Text('ElecPay', style: AppText.display.copyWith(color: c.ink, letterSpacing: -1)),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      'Votre électricité, vos factures et vos paiements au même endroit.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(color: c.inkMuted),
                    ),
                  ),
                  const SizedBox(height: Space.s12),
                  switch (decision) {
                    ShowUnreachable(:final address) => _Unreachable(address: address),
                    ShowUnavailable() => StateBlock(
                      icon: AppIcons.error,
                      title: 'Service indisponible',
                      message:
                          'ElecPay est momentanément indisponible. Réessayez dans quelques '
                          'minutes.',
                      tone: StateTone.error,
                      actionLabel: 'Réessayer',
                      onAction: () => ref.invalidate(startupDecisionProvider),
                    ),
                    _ => const _LoadingBar(),
                  },
                  if (demo) ...[const SizedBox(height: Space.s4), const DemoBadge()],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: c.volt,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.xl)),
        boxShadow: context.shadows.volt,
      ),
      child: AppIcon(AppIcons.energy, size: 44, color: c.onVolt, label: 'ElecPay'),
    );
  }
}

/// Barre de chargement de la maquette : 120 × 4, un segment jaune qui glisse (1,4 s), immobile si
/// le téléphone réduit les animations.
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Chargement',
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        child: SizedBox(
          width: 120,
          height: 4,
          child: ColoredBox(
            color: c.surface3,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => FractionallySizedBox(
                widthFactor: 0.4,
                alignment: Alignment(-1 + 3.5 * Motion.curve.transform(_controller.value), 0),
                child: child,
              ),
              child: ColoredBox(color: c.volt),
            ),
          ),
        ),
      ),
    );
  }
}

class _Unreachable extends ConsumerWidget {
  const _Unreachable({required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Column(
      children: [
        StateBlock.offline(onRetry: () => ref.invalidate(startupDecisionProvider)),
        if (kDebugMode)
          Text(
            'Développement : API attendue à $address. En USB ou sans fil, lancez '
            '« adb reverse tcp:8000 tcp:8000 » ; en Wi-Fi direct, vérifiez l’IP du PC.',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: c.inkMuted),
          ),
      ],
    );
  }
}
