import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_text_field.dart';
import 'support_rules.dart';

/// Écran 16 : Assistance (maquette `Assistance.dc.html`) : recherche, questions fréquentes,
/// contacts, et rappel que les pannes relèvent d'E²C.
///
/// Contacts du support (D9.3, D9.4) : pas encore prêts (décision de Loick du 21/11/2026) →
/// « bientôt disponibles », sans aucun faux numéro ni fausse adresse.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _search = TextEditingController();

  /// Question ouverte (maquette : la première l'est à l'arrivée) ; `null` : aucune.
  String? _open = faqs.first.question;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final found = searchFaqs(_search.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistance')),
      body: SafeArea(
        child: ListView(
          key: const Key('support.list'),
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s8),
          children: [
            AppTextField(
              key: const Key('support.search'),
              label: 'Rechercher dans l’aide',
              controller: _search,
              helper: 'Ex. paiement, compteur, reçu',
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.s4),
            Semantics(
              header: true,
              child: Text(
                'QUESTIONS FRÉQUENTES',
                style: AppText.overline.copyWith(color: c.inkMuted),
              ),
            ),
            const SizedBox(height: 6),
            if (found.isEmpty)
              Container(
                key: const Key('support.noResult'),
                padding: const EdgeInsets.all(Space.s4),
                decoration: BoxDecoration(
                  color: c.surface1,
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
                ),
                child: Text(
                  'Aucune question ne correspond à « ${_search.text.trim()} ».',
                  style: AppText.bodySm.copyWith(color: c.inkMuted),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface1,
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final (i, faq) in found.indexed)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                            ),
                            child: _FaqItem(
                              key: Key('support.faq.${faqs.indexOf(faq)}'),
                              faq: faq,
                              open: _open == faq.question,
                              onTap: () => setState(
                                () => _open = _open == faq.question ? null : faq.question,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Space.s4),
            Semantics(
              header: true,
              child: Text('NOUS CONTACTER', style: AppText.overline.copyWith(color: c.inkMuted)),
            ),
            const SizedBox(height: 6),
            Container(
              key: const Key('support.contacts'),
              padding: const EdgeInsets.all(Space.s4),
              decoration: BoxDecoration(
                color: c.surface1,
                borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.hourglass, color: c.inkMuted),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contacts du support : bientôt disponibles',
                          style: AppText.bodyStrong.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: Space.s1),
                        Text(
                          'Pour un problème de paiement, gardez la référence TX de la transaction '
                          '(dans Paiements et reçus) : elle vous sera demandée.',
                          style: AppText.bodySm.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s3),
            Container(
              key: const Key('support.e2c'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.s3),
              decoration: BoxDecoration(
                color: c.warningSoft,
                borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.alert, size: 18, color: c.warningText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Coupure, panne ou problème sur le réseau électrique : contactez directement '
                      'E²C. ElecPay ne gère que vos factures et vos paiements.',
                      style: AppText.bodySm.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.faq, required this.open, required this.onTap, super.key});

  final Faq faq;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: faq.question,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: Space.s2),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: AppIcon(AppIcons.dropdown, size: 16, color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
            child: Text(faq.answer, style: AppText.bodySm.copyWith(color: c.inkMuted)),
          ),
      ],
    );
  }
}
