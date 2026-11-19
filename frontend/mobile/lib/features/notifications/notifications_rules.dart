import 'package:flutter/widgets.dart';

import '../../core/models/notifications.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/statuses.dart';

// Règles de l'écran 13, sans réseau ni affichage : testées une à une
// (test/features/notifications/notifications_rules_test.dart). Guide : backend/docs/NOTIFICATIONS.md.

/// Onglet ouvert quand on touche une notification (F4.3 : l'onglet concerné ; les écrans précis
/// — détail de facture, reçu, compteur — arrivent aux étapes F5 à F8). `null` : aucun écran
/// particulier (annonce de l'équipe, type inconnu) : la notification est seulement marquée lue.
AppTab? notificationTab(NotificationPublic n) => switch (n.type) {
  NotificationTypes.billIssued ||
  NotificationTypes.billDueSoon ||
  NotificationTypes.billOverdue ||
  NotificationTypes.paymentSucceeded ||
  NotificationTypes.paymentFailed => AppTab.bills,
  NotificationTypes.consumptionAnomaly || NotificationTypes.highConsumption => AppTab.consumption,
  NotificationTypes.invitationReceived => AppTab.account,
  _ => null,
};

/// Icône et couleur d'une notification (maquette : réussi vert, échec rouge, consommation orange,
/// le reste bleu).
({IconData icon, StatusTone tone}) notificationStyle(String type) => switch (type) {
  NotificationTypes.paymentSucceeded => (icon: AppIcons.check, tone: StatusTone.success),
  NotificationTypes.paymentFailed => (icon: AppIcons.cross, tone: StatusTone.error),
  NotificationTypes.billOverdue => (icon: AppIcons.alert, tone: StatusTone.error),
  NotificationTypes.consumptionAnomaly ||
  NotificationTypes.highConsumption => (icon: AppIcons.energy, tone: StatusTone.warning),
  NotificationTypes.invitationReceived => (icon: AppIcons.household, tone: StatusTone.current),
  NotificationTypes.announcement => (icon: AppIcons.info, tone: StatusTone.current),
  _ => (icon: AppIcons.bill, tone: StatusTone.current),
};

/// Titre d'un groupe (`group` de l'API).
String notificationGroupTitle(String group) => switch (group) {
  NotificationGroups.today => 'Aujourd’hui',
  NotificationGroups.thisWeek => 'Cette semaine',
  _ => 'Plus tôt',
};

/// « 3 non lues », « 1 non lue », « Tout est lu ».
String unreadText(int count) => switch (count) {
  0 => 'Tout est lu',
  1 => '1 non lue',
  _ => '$count non lues',
};
