import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/models/households.dart';
import '../../core/session/session_providers.dart';
import '../consumption/consumption_data.dart';
import '../home/home_data.dart';

// Écran 15 : Compteurs et foyers. Lectures par le cache hors ligne (sauf les invitations, jamais en
// cache) ; actions par l'API authentifiée, envoyées UNE fois (aucune relance automatique). Les
// droits viennent du serveur (`my_role`, `can_manage`) : l'écran ne les recalcule jamais.
// Guide : backend/docs/FOYERS_COMPTEURS.md.

/// Carte d'un foyer : compteurs, membres (et invitations en attente pour le propriétaire), droits.
final householdDetailProvider = FutureProvider.family<Fetched<HouseholdDetail>, int>(
  (ref, id) => ref.watch(cachedApiProvider).get('/households/$id', HouseholdDetail.fromJson),
);

/// Invitations reçues en attente (`GET /invitations`) : toujours lues en direct.
final invitationsProvider = FutureProvider<List<InvitationPublic>>(
  (ref) async =>
      (await ref.watch(cachedApiProvider).getList('/invitations', InvitationPublic.fromJson)).data,
);

/// Foyers qui ont une facture à payer (badge « À payer » de la maquette). Illisible : aucun badge.
final householdsToPayProvider = FutureProvider<Set<int>>((ref) async {
  try {
    final bills = (await ref.watch(toPayBillsProvider.future)).data.items;
    return {for (final b in bills) b.householdId};
  } on Object {
    return const {};
  }
});

/// Actions de l'écran 15. Chacune relit ce qu'elle a changé ; une erreur de l'API remonte telle
/// quelle (l'écran l'affiche sous le bon champ ou dans la feuille).
class HouseholdActions {
  const HouseholdActions(this._ref);

  final Ref _ref;

  void _refreshHousehold(int householdId) {
    _ref
      ..invalidate(householdsProvider)
      ..invalidate(householdDetailProvider(householdId))
      ..invalidate(householdMetersProvider(householdId))
      ..invalidate(allMetersProvider);
  }

  /// Accepter une invitation : le foyer rejoint apparaît dans la liste.
  Future<HouseholdDetail> accept(int invitationId) async {
    final household = await _ref
        .read(authenticatedApiProvider)
        .postObject('/invitations/$invitationId/accept', HouseholdDetail.fromJson);
    _ref
      ..invalidate(invitationsProvider)
      ..invalidate(householdsProvider)
      ..invalidate(allMetersProvider)
      ..invalidate(toPayBillsProvider);
    return household;
  }

  Future<void> decline(int invitationId) async {
    await _ref.read(authenticatedApiProvider).postNoContent('/invitations/$invitationId/decline');
    _ref.invalidate(invitationsProvider);
  }

  /// Créer un foyer (propriétaire : le compte connecté).
  Future<HouseholdDetail> createHousehold(HouseholdCreate request) async {
    final household = await _ref
        .read(authenticatedApiProvider)
        .postObject('/households', HouseholdDetail.fromJson, body: request);
    _ref.invalidate(householdsProvider);
    return household;
  }

  /// Ajouter un compteur (N° de branchement + N° client vérifiés chez E²C).
  Future<MeterAddResponse> addMeter(int householdId, MeterAddRequest request) async {
    final added = await _ref
        .read(authenticatedApiProvider)
        .postObject('/households/$householdId/meters', MeterAddResponse.fromJson, body: request);
    _refreshHousehold(householdId);
    _ref.invalidate(toPayBillsProvider); // l'historique importé peut laisser une facture à payer
    return added;
  }

  /// Inviter un payeur délégué (ou un lecteur) : le numéro doit avoir un compte ElecPay.
  Future<MemberPublic> invite(int householdId, InviteRequest request) async {
    final member = await _ref
        .read(authenticatedApiProvider)
        .postObject('/households/$householdId/members', MemberPublic.fromJson, body: request);
    _refreshHousehold(householdId);
    return member;
  }

  /// Retirer un membre, ou annuler une invitation en attente (propriétaire).
  Future<void> removeMember(int householdId, int memberId) async {
    await _ref
        .read(authenticatedApiProvider)
        .deleteNoContent('/households/$householdId/members/$memberId');
    _refreshHousehold(householdId);
  }

  /// Quitter un foyer (payeur délégué ou lecteur ; jamais le propriétaire).
  Future<void> leave(int householdId) async {
    await _ref.read(authenticatedApiProvider).postNoContent('/households/$householdId/leave');
    _refreshHousehold(householdId);
    _ref.invalidate(toPayBillsProvider);
  }

  /// Renommer un foyer (seul le nom part : les autres champs ne sont pas effacés).
  Future<void> renameHousehold(int householdId, String name) async {
    await _ref
        .read(authenticatedApiProvider)
        .patchObject('/households/$householdId', HouseholdDetail.fromJson, body: {'name': name});
    _refreshHousehold(householdId);
  }

  /// Renommer un compteur (`null` ou vide : retirer son nom).
  Future<void> renameMeter(int householdId, int meterId, String? label) async {
    await _ref
        .read(authenticatedApiProvider)
        .patchObject('/meters/$meterId', MeterDetail.fromJson, body: {'label': label});
    _refreshHousehold(householdId);
  }
}

final householdActionsProvider = Provider<HouseholdActions>(HouseholdActions.new);
