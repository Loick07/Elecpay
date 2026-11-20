import '../../core/format/formats.dart';
import '../../core/models/households.dart';

// Règles de l'écran 15 (Compteurs et foyers), sans réseau ni affichage : testées une à une
// (test/features/households/households_rules_test.dart). Guide : backend/docs/FOYERS_COMPTEURS.md.

/// Mon rôle dans un foyer, tel qu'affiché : « Propriétaire », « Payeur délégué », « Lecteur ».
/// Rôle inconnu (ajouté plus tard par l'API) : « Membre ».
String householdRoleLabel(HouseholdRole role) => switch (role) {
  HouseholdRoles.owner => 'Propriétaire',
  HouseholdRoles.payer => 'Payeur délégué',
  HouseholdRoles.viewer => 'Lecteur',
  _ => 'Membre',
};

/// Rôle d'un membre en minuscules, dans une phrase (« Grâce Ngoma · payeur délégué »). Toujours au
/// masculin générique : le genre d'une personne ne se devine pas à son prénom.
String memberRoleLabel(MemberRole role) => householdRoleLabel(role).toLowerCase();

/// « Mpita, Pointe-Noire · Propriétaire » (quartier facultatif).
String householdPlaceLine(String? district, String city, HouseholdRole myRole) =>
    '${[?district, city].join(', ')} · ${householdRoleLabel(myRole)}';

/// Initiales d'un nom pour la pastille ronde : « Grâce Ngoma » → « GN » ; « Arnaud » → « A ».
String initials(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  final first = words.first[0];
  final last = words.length > 1 ? words.last[0] : '';
  return '$first$last'.toUpperCase();
}

/// Puissance souscrite : 6000 VA → « 6 kVA » ; 4500 → « 4,5 kVA » ; inconnue → « — ».
String subscribedPowerLabel(int? va) =>
    va == null ? '—' : '${formatDecimal(va / 1000, maxDecimals: 1)}${unitSpace}kVA';

/// Nom d'un compteur dans sa carte : son nom s'il en a un, sinon « Compteur ».
String meterCardName(MeterSummary meter) => meter.label ?? 'Compteur';

/// Ligne des membres au bas d'une carte, à côté des pastilles :
/// - propriétaire seul : « Vous seul » ;
/// - un membre : « Grâce Ngoma · payeur délégué » ;
/// - plusieurs : « Grâce Ngoma et 2 autres » ;
/// - invitations en attente (le propriétaire les voit) : « · 1 invitation en attente ».
/// Je ne suis pas propriétaire : « Propriétaire : Loick Makosso ».
String membersLine(HouseholdDetail h) {
  if (h.myRole != HouseholdRoles.owner) return 'Propriétaire : ${h.owner.fullName}';
  final active = h.members.where((m) => m.status == MemberStatuses.active).toList();
  final invited = h.members.where((m) => m.status == MemberStatuses.invited).length;
  final who = switch (active.length) {
    0 => 'Vous seul',
    1 => '${active.single.person.fullName} · ${memberRoleLabel(active.single.role)}',
    final n => '${active.first.person.fullName} et ${n - 1} autre${n > 2 ? 's' : ''}',
  };
  if (invited == 0) return who;
  return '$who · $invited invitation${invited > 1 ? 's' : ''} en attente';
}

/// Pastilles rondes au bas d'une carte : le propriétaire puis les membres actifs (3 au plus).
List<String> memberInitials(HouseholdDetail h) => [
  initials(h.owner.fullName),
  for (final m in h.members.where((m) => m.status == MemberStatuses.active).take(2))
    initials(m.person.fullName),
];

/// Invitation reçue : « Marie Loemba vous invite comme payeur délégué ».
String invitationTitle(InvitationPublic i) =>
    '${i.invitedBy.fullName} vous invite comme ${memberRoleLabel(i.role)}';

/// Champ vide de la feuille « Ajouter un compteur » : son message ; rempli : `null`. Les formats
/// (branchement, N° client) sont vérifiés par l'API, qui accepte espaces, tirets et minuscules.
String? addMeterFieldError(String field, String value) {
  if (value.trim().isNotEmpty) return null;
  return switch (field) {
    'reference' => 'Saisissez le N° de branchement.',
    'customer_number' => 'Saisissez le N° client.',
    'name' => 'Donnez un nom au foyer.',
    _ => 'Indiquez la ville.',
  };
}

/// Compteur ajouté : « Branchement 0018095408 · Centre POINTE-NOIRE · 6 kVA » (ce qu'E²C a renvoyé).
String addedMeterLine(MeterDetail meter) => [
  'Branchement ${formatReference(meter.reference)}',
  if (meter.e2cCenter case final center?) 'Centre $center',
  if (meter.subscribedPowerVa case final va?) subscribedPowerLabel(va),
].join(' · ');

/// Historique importé avec le compteur : « Historique importé : 9 factures et 540 relevés (données
/// de démo) ». Jamais une donnée simulée présentée comme réelle.
String importedHistoryLine(HistoryImportPublic history) {
  String plural(int n, String word) => '$n $word${n > 1 ? 's' : ''}';
  final demo = history.source == 'simulated' ? ' (données de démo)' : '';
  if (history.bills == 0 && history.readings == 0) return 'Aucun historique importé$demo.';
  return 'Historique importé : ${plural(history.bills, 'facture')} et '
      '${plural(history.readings, 'relevé')}$demo.';
}
