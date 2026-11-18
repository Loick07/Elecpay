import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format/phone.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.g.dart';

/// Champ de saisie de la charte (`frontend/design/components/TextField`) : libellé AU-DESSUS (il
/// reste visible), aide ou erreur EN DESSOUS. Hauteur 52, fond `surface-1`, bordure `line` ;
/// focus : bordure `current` + halo `current-soft` ; erreur : bordure `error` et message qui dit
/// comment corriger.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.helper,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.password = false,
    this.mono = false,
    this.prefix,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? helper;

  /// Message d'erreur (en français, dit comment corriger) ; `null` : pas d'erreur.
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  /// Mot de passe : caché, avec un bouton pour l'afficher.
  final bool password;

  /// Référence (compteur, facture) : police mono.
  final bool mono;

  /// Texte fixe avant la saisie (ex. « +242 »).
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focus = FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = widget.error != null;
    final focused = _focus.hasFocus;
    final borderColor = hasError ? c.error : (focused ? c.current : c.line);
    final textStyle = (widget.mono ? AppText.reference : AppText.body).copyWith(color: c.ink);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: AppText.bodySm.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.s2),
          AnimatedContainer(
            duration: Motion.of(context, Motion.press),
            curve: Motion.curve,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: Space.s4),
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              border: Border.all(color: borderColor, width: focused || hasError ? 1.5 : 1),
              boxShadow: [
                if (focused && !hasError) BoxShadow(color: c.currentSoft, spreadRadius: 3),
              ],
            ),
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  Text(widget.prefix!, style: textStyle.copyWith(color: c.inkMuted)),
                  const SizedBox(width: Space.s2),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    autofillHints: widget.autofillHints,
                    obscureText: widget.password && _hidden,
                    enableSuggestions: !widget.password,
                    autocorrect: !widget.password,
                    style: textStyle,
                    cursorColor: c.current,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: Space.s3),
                    ),
                  ),
                ),
                if (widget.password)
                  IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip: _hidden ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                    icon: AppIcon(_hidden ? AppIcons.show : AppIcons.hide, color: c.inkMuted),
                  ),
              ],
            ),
          ),
          if (hasError || widget.helper != null) ...[
            const SizedBox(height: Space.s2),
            Text(
              widget.error ?? widget.helper!,
              style: AppText.bodySm.copyWith(color: hasError ? c.errorText : c.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Champ « numéro de téléphone » : préfixe +242 fixe, clavier numérique, regroupement automatique
/// « 06 123 45 67 ». La valeur à envoyer à l'API : [PhoneField.normalized].
class PhoneField extends StatelessWidget {
  const PhoneField({
    required this.controller,
    this.label = 'Numéro de téléphone',
    this.error,
    this.helper,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final String? helper;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// « +242061234567 », ou `null` si la saisie est invalide (le message : [phoneError]).
  static String? normalized(String text) {
    try {
      return normalizeCongoPhone(text);
    } on PhoneFormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: label,
    controller: controller,
    error: error,
    helper: helper,
    prefix: '+242',
    keyboardType: TextInputType.phone,
    textInputAction: textInputAction,
    autofillHints: const [AutofillHints.telephoneNumberNational],
    inputFormatters: [CongoPhoneInputFormatter()],
    onSubmitted: onSubmitted,
    onChanged: onChanged,
  );
}

/// Pendant la saisie : chiffres seulement, 9 au plus, groupés « 06 123 45 67 ». Un numéro collé
/// avec l'indicatif (« +242 06… », « 00242… ») est ramené aux 9 chiffres nationaux.
class CongoPhoneInputFormatter extends TextInputFormatter {
  /// « 061234567 » → « 06 123 45 67 » (groupes 2-3-2-2).
  static String group(String digits) {
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) out.write(' ');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00242')) {
      digits = digits.substring(5);
    } else if (digits.length > 9 && digits.startsWith('242')) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);
    final text = group(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
