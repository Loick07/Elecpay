import 'package:flutter/material.dart';

import '../format/numbers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'status_badge.dart';
import 'statuses.dart';

/// Ligne de la liste des factures (`frontend/design/components/BillRow`, maquette de l'écran 6) :
/// icône facture dans un carré `surface-2` ; foyer puis ligne secondaire (« 417,4 kWh · échéance
/// le 18 nov. », « Payée le 12 sept. par Grâce Ngoma ») ; montant au-dessus du badge. Toute la
/// ligne ouvre le détail.
class BillRow extends StatelessWidget {
  const BillRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.onTap,
    super.key,
  });

  /// Le foyer (« Maison Mpita »).
  final String title;
  final String subtitle;
  final int amount;
  final StatusStyle status;
  final VoidCallback onTap;

  /// Au-delà de cet agrandissement du texte, le montant et le badge passent SOUS le foyer (sinon
  /// la ligne déborde sur un écran de 360 points, vu au test à 200 %).
  static const stackedFromTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amountText = formatFcfa(amount);
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= stackedFromTextScale;
    final amountAndStatus = Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(amountText, style: AppText.amount.copyWith(color: c.ink, fontSize: 15)),
        const SizedBox(height: Space.s1),
        StatusBadge(status),
      ],
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.bodyStrong.copyWith(color: c.ink)),
        Text(subtitle, style: AppText.bodySm.copyWith(color: c.inkMuted)),
        if (stacked) ...[const SizedBox(height: Space.s2), amountAndStatus],
      ],
    );
    return Semantics(
      button: true,
      label: '$title, $subtitle, $amountText, ${status.label}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
                  ),
                  child: AppIcon(AppIcons.bill, color: c.inkMuted),
                ),
                const SizedBox(width: Space.s3),
                Expanded(child: texts),
                if (!stacked) ...[const SizedBox(width: Space.s3), amountAndStatus],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Groupe de lignes de la maquette : titre en capitales (« SEPTEMBRE – OCTOBRE 2026 ») puis une
/// carte `surface-1` arrondie, avec un séparateur `line` entre les lignes.
class BillRowGroup extends StatelessWidget {
  const BillRowGroup({required this.title, required this.rows, super.key});

  final String title;
  final List<BillRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title.toUpperCase(), style: AppText.overline.copyWith(color: c.inkMuted)),
        ),
        const SizedBox(height: Space.s2),
        Material(
          color: c.surface1,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
