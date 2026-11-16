import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';

/// Page de CONTRÔLE de la charte (outil de développement, F0.2) : couleurs, échelle de texte,
/// bouton, champ, références, dans le thème Nuit ou Jour. Pas un écran de l'application livrée.
class CharteScreen extends StatefulWidget {
  const CharteScreen({super.key});

  @override
  State<CharteScreen> createState() => _CharteScreenState();
}

class _CharteScreenState extends State<CharteScreen> {
  bool _night = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _night ? AppTheme.dark : AppTheme.light,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charte ElecPay'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _night = !_night),
            child: Text(
              _night ? 'Nuit' : 'Jour',
              style: AppText.bodyStrong.copyWith(color: c.voltText),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.s4),
        children: [
          Text('COULEURS', style: AppText.overline.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.s2),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              _swatch('bg', c.bg, c),
              _swatch('surface-1', c.surface1, c),
              _swatch('surface-2', c.surface2, c),
              _swatch('volt', c.volt, c),
              _swatch('current', c.current, c),
              _swatch('success', c.success, c),
              _swatch('warning', c.warning, c),
              _swatch('error', c.error, c),
            ],
          ),
          const SizedBox(height: Space.s6),
          Text('TEXTES', style: AppText.overline.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.s2),
          Text('12 500 FCFA', style: AppText.amountHero.copyWith(color: c.ink)),
          Text('Bonjour Loick', style: AppText.display.copyWith(color: c.ink)),
          Text('Mes factures', style: AppText.h1.copyWith(color: c.ink)),
          Text('Consommation de novembre', style: AppText.h2.copyWith(color: c.ink)),
          Text('8 340 FCFA', style: AppText.amount.copyWith(color: c.ink)),
          Text('Votre facture est disponible.', style: AppText.body.copyWith(color: c.ink)),
          Text('Échéance le 18 nov. 2026', style: AppText.bodySm.copyWith(color: c.inkMuted)),
          Text('kWh · estimé', style: AppText.caption.copyWith(color: c.inkMuted)),
          Text('EP-2026-000123', style: AppText.reference.copyWith(color: c.ink)),
          const SizedBox(height: Space.s6),
          FilledButton(onPressed: () {}, child: const Text('Payer 31 420 FCFA')),
          const SizedBox(height: Space.s3),
          const TextField(decoration: InputDecoration(hintText: '+242 06 123 45 67')),
        ],
      ),
    );
  }

  Widget _swatch(String name, Color color, ElecPayColors c) {
    return Container(
      width: 96,
      height: 64,
      padding: const EdgeInsets.all(Space.s2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.sm)),
        border: Border.all(color: c.line),
      ),
      alignment: Alignment.bottomLeft,
      child: Text(
        name,
        style: AppText.caption.copyWith(
          color: color.computeLuminance() > 0.4 ? const Color(0xFF0A1628) : const Color(0xFFF2F5FA),
        ),
      ),
    );
  }
}
