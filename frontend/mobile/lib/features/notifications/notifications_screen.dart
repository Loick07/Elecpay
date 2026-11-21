import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/format/formats.dart';
import '../../core/models/notifications.dart';
import '../../core/network/api_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/load_more.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_block.dart';
import '../../core/widgets/statuses.dart';
import '../home/home_screen.dart' show homeClockProvider;
import 'notifications_data.dart';
import 'notifications_rules.dart';

/// Écran 13 : Notifications (maquette `Notifications.dc.html`). Groupes Aujourd'hui / Cette semaine /
/// Plus tôt, non lues mises en avant, « Tout marquer comme lu », pages de 20 au défilement.
/// Toucher une notification la marque lue et ouvre l'onglet concerné.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    // Chaque ouverture relit la liste (la précédente reste affichée pendant ce temps).
    if (ref.read(notificationsProvider).hasValue) ref.invalidate(notificationsProvider);
  }

  Future<void> _open(NotificationPublic n) async {
    unawaited(ref.read(notificationsProvider.notifier).markRead(n));
    // « Paiement réussi » avec son reçu : le reçu (écran 10, F6.4) ; sinon l'onglet concerné.
    if (n.type == NotificationTypes.paymentSucceeded && n.data?['receipt_id'] is int) {
      await context.push(Routes.receipt(n.data!['receipt_id'] as int));
      return;
    }
    // Invitation reçue : l'écran Compteurs et foyers, où elle s'accepte (F8).
    if (n.type == NotificationTypes.invitationReceived) {
      await context.push(Routes.households);
      return;
    }
    final tab = notificationTab(n);
    if (tab != null) context.go(tab.path);
  }

  Future<void> _markAll() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } on ApiFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    try {
      await ref.read(notificationsProvider.future);
    } on Object {
      // L'état d'erreur s'affiche.
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: switch (notifications) {
            AsyncValue(:final value?) => _list(value),
            AsyncError(:final error) => ListView(
              children: [
                if (error case final ApiFailure failure)
                  stateForFailure(failure, what: 'vos notifications', onRetry: _retry)
                else
                  StateBlock.error(what: 'vos notifications', onRetry: _retry),
              ],
            ),
            _ => ListView(
              children: [
                AppSkeleton(
                  loading: true,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.s4),
                    child: _GroupCard(
                      children: [
                        for (var i = 0; i < 3; i++)
                          _NotificationRow(
                            title: 'Nouvelle facture',
                            body: 'Maison Mpita, sept.–oct. : 31 420 FCFA à payer.',
                            time: '3 nov.',
                            type: NotificationTypes.billIssued,
                            unread: false,
                            first: i == 0,
                            onTap: () {},
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  void _retry() => unawaited(_refresh());

  Widget _list(NotificationsView view) {
    final c = context.colors;
    final now = ref.read(homeClockProvider)();
    final canWrite = view.offline == null;
    final children = <Widget>[
      if (view.offline case final cached?) ...[
        OfflineBanner(cached.label),
        const SizedBox(height: Space.s3),
      ],
      // Wrap : texte agrandi, le bouton passe sous le compteur au lieu de déborder.
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(unreadText(view.unreadCount), style: AppText.bodySm.copyWith(color: c.inkMuted)),
          TextButton(
            key: const Key('notifications.markAll'),
            onPressed: canWrite && view.unreadCount > 0 && !_markingAll ? _markAll : null,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              'Tout marquer comme lu',
              style: AppText.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: canWrite && view.unreadCount > 0 ? c.voltText : c.inkFaint,
              ),
            ),
          ),
        ],
      ),
    ];

    if (view.items.isEmpty) {
      children.add(
        const StateBlock.empty(
          icon: AppIcons.notifications,
          title: 'Aucune notification',
          message: 'Vos factures, paiements et alertes apparaîtront ici.',
        ),
      );
    } else {
      // Un titre à chaque changement de groupe (l'API trie de la plus récente à la plus ancienne).
      var start = 0;
      while (start < view.items.length) {
        final group = view.items[start].group;
        var end = start;
        while (end < view.items.length && view.items[end].group == group) {
          end++;
        }
        final items = view.items.sublist(start, end);
        children
          ..add(const SizedBox(height: Space.s4))
          ..add(
            Semantics(
              header: true,
              child: Text(
                notificationGroupTitle(group).toUpperCase(),
                style: AppText.overline.copyWith(color: c.inkMuted),
              ),
            ),
          )
          ..add(const SizedBox(height: Space.s2))
          ..add(
            _GroupCard(
              children: [
                for (final (i, n) in items.indexed)
                  _NotificationRow(
                    key: Key('notification.${n.id}'),
                    title: n.title,
                    body: n.body,
                    time: formatNotificationTime(n.createdAt, n.group, now: now),
                    type: n.type,
                    unread: !n.isRead,
                    first: i == 0,
                    onTap: () => _open(n),
                  ),
              ],
            ),
          );
        start = end;
      }
      children.add(const SizedBox(height: Space.s4));
      if (view.moreFailure != null) {
        // Même bas de liste que Factures et Historique (`LoadMoreFooter`).
        children.add(
          LoadMoreFooter(
            key: const Key('notifications.more.retry'),
            failed: true,
            onLoad: () => ref.read(notificationsProvider.notifier).loadMore(),
          ),
        );
      } else if (view.hasMore) {
        children.add(
          LoadMoreFooter(
            key: ValueKey('notifications.more.${view.items.length}'),
            onLoad: () => ref.read(notificationsProvider.notifier).loadMore(),
          ),
        );
      }
    }

    return ListView(
      key: const Key('notifications.list'),
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s8),
      children: children,
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.colors.surface1,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.lg)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.unread,
    required this.first,
    required this.onTap,
    super.key,
  });

  final String title;
  final String body;
  final String time;
  final String type;
  final bool unread;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = notificationStyle(type);
    final tone = StatusStyle('', style.tone, style.icon);
    return Semantics(
      container: true,
      button: true,
      label: [if (unread) 'Non lue', title, body, time].join('. '),
      excludeSemantics: true,
      child: Material(
        color: unread ? c.surface2 : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: first ? null : Border(top: BorderSide(color: c.line)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.background(c),
                    borderRadius: const BorderRadius.all(Radius.circular(Radii.md)),
                  ),
                  child: AppIcon(style.icon, color: tone.foreground(c)),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: Space.s2,
                        children: [
                          Text(
                            title,
                            style: AppText.body.copyWith(
                              color: c.ink,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          Text(time, style: AppText.caption.copyWith(color: c.inkMuted)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body, style: AppText.bodySm.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s2),
                Container(
                  key: unread ? const Key('notification.unreadDot') : null,
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: unread ? c.volt : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
