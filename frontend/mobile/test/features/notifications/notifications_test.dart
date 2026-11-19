import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/models/notifications.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/core/widgets/bottom_nav.dart';
import 'package:elecpay/features/home/home_data.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:elecpay/features/notifications/notifications_data.dart';
import 'package:elecpay/features/notifications/notifications_rules.dart';
import 'package:elecpay/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_home_backend.dart';
import '../../support/fake_server.dart';
import '../../support/itel_screen.dart';
import '../../support/openapi.dart';

final _now = DateTime.utc(2026, 11, 12, 15);

NotificationPublic _n(String type, {Map<String, dynamic>? data}) => NotificationPublic.fromJson({
  ...OpenApi.load().sample('NotificationPublic'),
  'type': type,
  'data': data,
});

/// L'écran 13 seul, sur l'itel ; les onglets sont de simples pages pour voir où l'on arrive.
Future<ProviderContainer> pumpNotifications(
  WidgetTester tester,
  FakeHomeBackend backend, {
  double textScale = 1.0,
  bool wait = true,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.notifications,
    routes: [
      for (final tab in AppTab.values)
        GoRoute(
          path: tab.path,
          builder: (context, state) => Scaffold(body: Text('Onglet ${tab.label}')),
        ),
      GoRoute(path: Routes.notifications, builder: (context, state) => const NotificationsScreen()),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [...backend.overrides(), homeClockProvider.overrideWithValue(() => _now)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  if (wait) await settle(tester);
  return container;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('règles', () {
    test('toucher une notification : l’onglet concerné (ou aucun)', () {
      expect(notificationTab(_n(NotificationTypes.billIssued)), AppTab.bills);
      expect(notificationTab(_n(NotificationTypes.billDueSoon)), AppTab.bills);
      expect(notificationTab(_n(NotificationTypes.billOverdue)), AppTab.bills);
      expect(notificationTab(_n(NotificationTypes.paymentSucceeded)), AppTab.bills);
      expect(notificationTab(_n(NotificationTypes.paymentFailed)), AppTab.bills);
      expect(notificationTab(_n(NotificationTypes.highConsumption)), AppTab.consumption);
      expect(notificationTab(_n(NotificationTypes.consumptionAnomaly)), AppTab.consumption);
      expect(notificationTab(_n(NotificationTypes.invitationReceived)), AppTab.account);
      expect(notificationTab(_n(NotificationTypes.announcement)), isNull);
      // `data` vide ou absent : même onglet (l'API peut omettre un champ).
      expect(notificationTab(_n(NotificationTypes.billIssued, data: {})), AppTab.bills);
    });

    test('chaque type du contrat a une règle d’onglet et un style', () {
      final types = OpenApi.load().enumValues('NotificationType');
      final known = {
        NotificationTypes.billIssued,
        NotificationTypes.billDueSoon,
        NotificationTypes.billOverdue,
        NotificationTypes.paymentSucceeded,
        NotificationTypes.paymentFailed,
        NotificationTypes.invitationReceived,
        NotificationTypes.consumptionAnomaly,
        NotificationTypes.highConsumption,
        NotificationTypes.announcement,
      };
      expect(types.toSet(), known, reason: 'nouveau type dans l’API : décider où il mène');
      expect(OpenApi.load().enumValues('NotificationGroup').toSet(), {
        NotificationGroups.today,
        NotificationGroups.thisWeek,
        NotificationGroups.earlier,
      });
    });

    test('type inconnu (version future de l’API) : aucun onglet, style neutre', () {
      expect(notificationTab(_n('nouveau_type')), isNull);
      expect(notificationStyle('nouveau_type').icon, notificationStyle('bill_issued').icon);
    });

    test('textes : groupes, non lues', () {
      expect(notificationGroupTitle('today'), 'Aujourd’hui');
      expect(notificationGroupTitle('this_week'), 'Cette semaine');
      expect(notificationGroupTitle('earlier'), 'Plus tôt');
      expect(unreadText(0), 'Tout est lu');
      expect(unreadText(1), '1 non lue');
      expect(unreadText(3), '3 non lues');
    });
  });

  group('écran', () {
    testWidgets('groupes, non lues mises en avant, compteur', (tester) async {
      await pumpNotifications(tester, FakeHomeBackend());
      expect(find.text('AUJOURD’HUI'), findsOneWidget);
      expect(find.text('CETTE SEMAINE'), findsOneWidget);
      expect(find.text('PLUS TÔT'), findsOneWidget);
      expect(find.text('3 non lues'), findsOneWidget);
      expect(find.byKey(const Key('notification.unreadDot')), findsNWidgets(3));
      expect(
        tester.getSemantics(find.byKey(const Key('notification.1'))).label,
        startsWith('Non lue. Paiement réussi.'),
      );
      expect(find.text('09:00'), findsNWidgets(2), reason: 'aujourd’hui : l’heure de Brazzaville');
    });

    testWidgets('toucher : marquée lue, l’onglet concerné s’ouvre, la cloche suit', (tester) async {
      final backend = FakeHomeBackend();
      final container = await pumpNotifications(tester, backend);
      await tester.tap(find.byKey(const Key('notification.3')));
      await settle(tester);
      expect(find.text('Onglet Conso'), findsOneWidget);
      expect(backend.server.requests.where((r) => r.path == '/notifications/3/read'), hasLength(1));
      expect(container.read(notificationsProvider).value!.unreadCount, 2);
      expect(container.read(unreadCountProvider).value, 2);
    });

    testWidgets('déjà lue : rien n’est envoyé, l’onglet s’ouvre quand même', (tester) async {
      final backend = FakeHomeBackend();
      await pumpNotifications(tester, backend);
      await tester.tap(find.byKey(const Key('notification.4')));
      await settle(tester);
      expect(find.text('Onglet Factures'), findsOneWidget);
      expect(backend.server.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('« Tout marquer comme lu » : plus aucune non lue, cloche à zéro', (tester) async {
      final backend = FakeHomeBackend();
      final container = await pumpNotifications(tester, backend);
      await tester.tap(find.byKey(const Key('notifications.markAll')));
      await settle(tester);
      expect(find.text('Tout est lu'), findsOneWidget);
      expect(find.byKey(const Key('notification.unreadDot')), findsNothing);
      expect(container.read(unreadCountProvider).value, 0);
      // Plus rien à marquer : bouton désactivé.
      final button = tester.widget<TextButton>(find.byKey(const Key('notifications.markAll')));
      expect(button.onPressed, isNull);
    });

    testWidgets('« Tout marquer comme lu » en échec : message de l’API, rien ne change', (
      tester,
    ) async {
      final backend = FakeHomeBackend()
        ..forced['/notifications/read-all'] = JsonReply(500, apiError('INTERNAL', 'Erreur'));
      await pumpNotifications(tester, backend);
      await tester.tap(find.byKey(const Key('notifications.markAll')));
      await settle(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('3 non lues'), findsOneWidget);
    });

    testWidgets('hors ligne (cache) : bannière datée, aucune écriture proposée', (tester) async {
      final backend = FakeHomeBackend();
      await pumpNotifications(tester, backend);
      await tester.pumpWidget(const SizedBox());
      backend.down.add('/notifications');
      await pumpNotifications(tester, backend);
      expect(
        find.textContaining('Hors connexion. Les données affichées datent du'),
        findsOneWidget,
      );
      final button = tester.widget<TextButton>(find.byKey(const Key('notifications.markAll')));
      expect(button.onPressed, isNull);
      await tester.tap(find.byKey(const Key('notification.1')));
      await settle(tester);
      expect(find.text('Onglet Factures'), findsOneWidget, reason: 'la lecture reste possible');
      expect(backend.server.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('hors ligne sans cache : bloc « Hors connexion »', (tester) async {
      await pumpNotifications(tester, FakeHomeBackend()..down.add('/notifications'));
      expect(find.text('Hors connexion'), findsOneWidget);
    });

    testWidgets('aucune notification : état vide', (tester) async {
      await pumpNotifications(tester, FakeHomeBackend()..notifications = []);
      expect(find.text('Aucune notification'), findsOneWidget);
      expect(find.text('Tout est lu'), findsOneWidget);
    });

    testWidgets('défilement par pages de 20, sans doublon', (tester) async {
      final backend = FakeHomeBackend()
        ..notifications = [
          for (var i = 1; i <= 45; i++)
            FakeHomeBackend.notification(
              i,
              type: 'bill_issued',
              group: 'earlier',
              title: 'Facture $i',
              read: true,
            ),
        ];
      final container = await pumpNotifications(tester, backend);
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byKey(const Key('notifications.list')), const Offset(0, -800));
        await settle(tester);
      }
      expect(container.read(notificationsProvider).value!.items, hasLength(45));
      final pages = backend.server.requests
          .where((r) => r.path == '/notifications')
          .map((r) => r.queryParameters['page'])
          .toList();
      expect(pages, [1, 2, 3]);
    });

    testWidgets('page suivante en échec : « Réessayer » en bas, puis la suite', (tester) async {
      final backend = FakeHomeBackend()
        ..notifications = [
          for (var i = 1; i <= 25; i++)
            FakeHomeBackend.notification(
              i,
              type: 'bill_issued',
              group: 'earlier',
              title: 'Facture $i',
              read: true,
            ),
        ];
      final container = await pumpNotifications(tester, backend);
      backend.down.add('/notifications');
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byKey(const Key('notifications.list')), const Offset(0, -800));
        await settle(tester);
      }
      expect(find.byKey(const Key('notifications.more.retry')), findsOneWidget);
      backend.down.clear();
      await tester.tap(find.byKey(const Key('notifications.more.retry')));
      await settle(tester);
      expect(container.read(notificationsProvider).value!.items, hasLength(25));
    });

    testWidgets('chaque ouverture relit la liste', (tester) async {
      final backend = FakeHomeBackend();
      final container = await pumpNotifications(tester, backend);
      expect(container.read(notificationsProvider).hasValue, isTrue);
      final router = GoRouter.of(tester.element(find.byType(NotificationsScreen)));
      router.go(AppTab.home.path);
      await settle(tester);
      router.go(Routes.notifications);
      await settle(tester);
      expect(backend.server.requests.where((r) => r.path == '/notifications'), hasLength(2));
    });
  });

  group('règle 2 : écran de l’itel, texte à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await pumpNotifications(tester, FakeHomeBackend(), textScale: scale);
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byKey(const Key('notifications.list')), const Offset(0, -300));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
