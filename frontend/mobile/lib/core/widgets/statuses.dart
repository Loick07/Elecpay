import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';

/// Famille de couleur d'un statut (table « Statuts » de la charte). Le jaune `volt` n'est JAMAIS
/// une couleur de statut.
enum StatusTone { current, warning, success, error, muted }

/// Un statut affiché : toujours une couleur, une icône ET un mot (la couleur seule ne suffit jamais).
@immutable
class StatusStyle {
  const StatusStyle(this.label, this.tone, this.icon);

  final String label;
  final StatusTone tone;
  final IconData icon;

  /// Couleur du TEXTE (`*-text` : lisible ≥ 4,5:1 sur le fond doux, dans les deux thèmes).
  Color foreground(ElecPayColors c) => switch (tone) {
    StatusTone.current => c.currentText,
    StatusTone.warning => c.warningText,
    StatusTone.success => c.successText,
    StatusTone.error => c.errorText,
    StatusTone.muted => c.inkMuted,
  };

  /// Couleur de l'ICÔNE : la couleur de base du statut (règle de la charte).
  Color iconColor(ElecPayColors c) => switch (tone) {
    StatusTone.current => c.current,
    StatusTone.warning => c.warning,
    StatusTone.success => c.success,
    StatusTone.error => c.error,
    StatusTone.muted => c.inkMuted,
  };

  /// Fond doux du badge.
  Color background(ElecPayColors c) => switch (tone) {
    StatusTone.current => c.currentSoft,
    StatusTone.warning => c.warningSoft,
    StatusTone.success => c.successSoft,
    StatusTone.error => c.errorSoft,
    StatusTone.muted => c.surface3,
  };
}

/// Statuts d'une facture (`BillStatus` du contrat). Un test vérifie que les clés sont EXACTEMENT les
/// valeurs de `backend/openapi.json`.
const billStatuses = <String, StatusStyle>{
  'unpaid': StatusStyle('À payer', StatusTone.current, AppIcons.clock),
  'pending_payment': StatusStyle('Paiement en cours', StatusTone.warning, AppIcons.hourglass),
  'paid': StatusStyle('Payée', StatusTone.success, AppIcons.check),
  'overdue': StatusStyle('En retard', StatusTone.error, AppIcons.alert),
  'cancelled': StatusStyle('Annulée', StatusTone.muted, AppIcons.cancelled),
};

/// Statuts d'une transaction (`TransactionStatus` du contrat), même règle.
const transactionStatuses = <String, StatusStyle>{
  'en_attente': StatusStyle('En attente', StatusTone.warning, AppIcons.hourglass),
  'reussie': StatusStyle('Réussie', StatusTone.success, AppIcons.check),
  'echouee': StatusStyle('Échouée', StatusTone.error, AppIcons.cross),
  'expiree': StatusStyle('Expirée', StatusTone.muted, AppIcons.expired),
};

/// Paiement dont on n'a pas la réponse (délai dépassé, état inconnu) : JAMAIS « Échouée ».
const transactionUnknown = StatusStyle(
  'Vérification en cours',
  StatusTone.warning,
  AppIcons.question,
);

/// Statut de facture qu'une version future de l'API ajouterait : affichage neutre, sans deviner.
const billUnknown = StatusStyle('Statut à vérifier', StatusTone.muted, AppIcons.question);

/// Style d'un statut de facture reçu de l'API.
StatusStyle billStatus(String status) => billStatuses[status] ?? billUnknown;

/// Style d'un statut de transaction ; `null` (pas de réponse) ou valeur inconnue :
/// « Vérification en cours ».
StatusStyle transactionStatus(String? status) => transactionStatuses[status] ?? transactionUnknown;
