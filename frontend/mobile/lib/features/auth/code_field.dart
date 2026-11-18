import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';

/// Champ du code reçu par SMS (6 chiffres), affiché en 6 cases comme la maquette.
///
/// Un SEUL vrai champ de saisie (invisible, posé sur les cases) : collage du code entier,
/// remplissage automatique du code SMS par Android, effacement naturel ; le lecteur d'écran lit
/// « Code reçu, 6 chiffres » et la valeur saisie.
class CodeField extends StatefulWidget {
  const CodeField({
    required this.controller,
    this.error,
    this.onChanged,
    this.onEditingComplete,
    super.key,
  });

  static const length = 6;

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;

  /// Touche « suivant » du clavier. Sans elle, Flutter passe à l'élément suivant de l'écran, qui
  /// peut être « Renvoyer le code » (vu sur l'itel au jalon F3.5) : l'écran envoie donc le curseur
  /// lui-même au bon champ.
  final VoidCallback? onEditingComplete;

  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  final _focus = FocusNode();

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(CodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = widget.controller.text;
    final hasError = widget.error != null;
    // La case où arrivera le prochain chiffre (la dernière si le code est complet).
    final current = math.min(code.length, CodeField.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text('Code reçu', style: AppText.bodySm.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(height: Space.s2),
        GestureDetector(
          onTap: _focus.requestFocus,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < CodeField.length; i++) ...[
                      if (i > 0) const SizedBox(width: Space.s2),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.surface1,
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                            border: Border.all(
                              color: hasError
                                  ? c.error
                                  : (_focus.hasFocus && i == current ? c.current : c.line),
                              width: hasError || (_focus.hasFocus && i == current) ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            i < code.length ? code[i] : '',
                            style: AppText.h2.copyWith(
                              color: c.ink,
                              fontSize: 20,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Le vrai champ, invisible, sur toute la surface des cases.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: Semantics(
                    label: 'Code reçu, ${CodeField.length} chiffres',
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(CodeField.length),
                      ],
                      showCursor: false,
                      enableInteractiveSelection: false,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: widget.onChanged,
                      onEditingComplete: widget.onEditingComplete,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Space.s2),
          Text(widget.error!, style: AppText.bodySm.copyWith(color: c.errorText)),
        ],
      ],
    );
  }
}
