import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/models/notifications.dart';
import '../../core/session/session_providers.dart';
import '../home/home_data.dart';

/// Ce que montre l'écran 13 : les pages déjà lues, et ce qu'il reste à charger.
@immutable
class NotificationsView {
  const NotificationsView({
    required this.items,
    required this.total,
    required this.unreadCount,
    this.offline,
    this.loadingMore = false,
    this.moreFailure,
  });

  final List<NotificationPublic> items;
  final int total;
  final int unreadCount;

  /// Première page lue dans le cache (« Hors connexion… ») : AUCUNE écriture n'est alors proposée.
  final CachedData<Object?>? offline;
  final bool loadingMore;

  /// Échec du chargement de la page suivante (« Réessayer » en bas de la liste).
  final Object? moreFailure;

  bool get hasMore => items.length < total;

  NotificationsView copyWith({
    List<NotificationPublic>? items,
    int? total,
    int? unreadCount,
    bool? loadingMore,
    Object? moreFailure,
    bool clearMoreFailure = false,
  }) => NotificationsView(
    items: items ?? this.items,
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
    offline: offline,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailure: clearMoreFailure ? null : (moreFailure ?? this.moreFailure),
  );
}

/// Liste des notifications, page par page (20), avec « lu » et « tout marquer comme lu ». Chaque
/// réponse de l'API met aussi à jour le point rouge de la cloche (`unreadCountProvider`), sans
/// interrogation périodique.
class NotificationsNotifier extends AsyncNotifier<NotificationsView> {
  static const pageSize = 20;
  int _page = 1;

  @override
  Future<NotificationsView> build() async {
    _page = 1;
    final first = await _fetch(1);
    final list = first.data;
    _syncBell(list.unreadCount);
    return NotificationsView(
      items: list.items,
      total: list.total,
      unreadCount: list.unreadCount,
      offline: first is CachedData<NotificationList> ? first : null,
    );
  }

  Future<Fetched<NotificationList>> _fetch(int page) => ref
      .read(cachedApiProvider)
      .get('/notifications', NotificationList.fromJson, query: {'page': page, 'size': pageSize});

  void _syncBell(int count) => ref.read(unreadCountProvider.notifier).set(count);

  /// Page suivante (défilement). Sans effet s'il n'y en a plus ou si elle est déjà en route.
  Future<void> loadMore() async {
    final view = state.value;
    if (view == null || !view.hasMore || view.loadingMore) return;
    state = AsyncData(view.copyWith(loadingMore: true, clearMoreFailure: true));
    try {
      final next = (await _fetch(_page + 1)).data;
      _page++;
      final known = {for (final n in view.items) n.id};
      state = AsyncData(
        view.copyWith(
          items: [...view.items, ...next.items.where((n) => !known.contains(n.id))],
          total: next.total,
          unreadCount: next.unreadCount,
          loadingMore: false,
          clearMoreFailure: true,
        ),
      );
    } on Object catch (failure) {
      state = AsyncData(view.copyWith(loadingMore: false, moreFailure: failure));
    }
  }

  /// Marque `n` comme lue (toucher une notification). Hors ligne ou déjà lue : rien n'est envoyé.
  /// Un échec n'empêche pas d'ouvrir l'écran : la notification reste simplement non lue.
  Future<void> markRead(NotificationPublic n) async {
    final view = state.value;
    if (view == null || n.isRead || view.offline != null) return;
    try {
      final read = await ref
          .read(authenticatedApiProvider)
          .postObject('/notifications/${n.id}/read', NotificationPublic.fromJson);
      final current = state.value ?? view;
      final unread = (current.unreadCount - 1).clamp(0, current.total);
      state = AsyncData(
        current.copyWith(
          items: [for (final item in current.items) item.id == read.id ? read : item],
          unreadCount: unread,
        ),
      );
      _syncBell(unread);
    } on Object {
      // Reste non lue ; aucune relance automatique.
    }
  }

  /// « Tout marquer comme lu ». Lève l'erreur de l'API (l'écran l'affiche) ; jamais hors ligne.
  Future<void> markAllRead() async {
    final view = state.value;
    if (view == null || view.offline != null || view.unreadCount == 0) return;
    final result = await ref
        .read(authenticatedApiProvider)
        .postObject('/notifications/read-all', ReadAllResult.fromJson);
    final current = state.value ?? view;
    state = AsyncData(
      current.copyWith(
        items: [for (final item in current.items) item.copyWith(isRead: true)],
        unreadCount: result.unreadCount,
      ),
    );
    _syncBell(result.unreadCount);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, NotificationsView>(
  NotificationsNotifier.new,
);
