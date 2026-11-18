import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import 'validation.dart';

/// Règles du mot de passe, cochées pendant la saisie (8 caractères, un chiffre, une lettre).
/// Communes à l'inscription et au nouveau mot de passe (mot de passe oublié).
class PasswordRules extends StatelessWidget {
  const PasswordRules(this.password, {super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final rule in passwordRules)
          Builder(
            builder: (context) {
              final ok = rule.ok(password);
              return Semantics(
                label: '${rule.label} : ${ok ? 'respecté' : 'pas encore'}',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      ok ? AppIcons.ruleMet : AppIcons.ruleUnmet,
                      size: 14,
                      color: ok ? c.success : c.inkFaint,
                    ),
                    const SizedBox(width: Space.s1),
                    Flexible(
                      child: Text(
                        rule.label,
                        style: AppText.caption.copyWith(
                          color: ok ? c.successText : c.inkMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
