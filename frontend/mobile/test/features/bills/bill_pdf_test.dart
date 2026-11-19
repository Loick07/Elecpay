import 'dart:async';
import 'dart:io';

import 'package:elecpay/app/riverpod_config.dart';
import 'package:elecpay/app/routes.dart';
import 'package:elecpay/core/cache/cache_policy.dart';
import 'package:elecpay/core/documents/documents.dart';
import 'package:elecpay/core/models/bills.dart';
import 'package:elecpay/core/network/api_failure.dart';
import 'package:elecpay/core/theme/app_theme.dart';
import 'package:elecpay/features/bills/bill_detail_screen.dart';
import 'package:elecpay/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_home_backend.dart';
import '../../support/itel_screen.dart';

/// Ouverture et partage simulés : on note ce qui est demandé.
class FakeDocumentActions implements DocumentActions {
  OpenOutcome outcome = OpenOutcome.opened;
  final opened = <String>[];
  final shared = <(String, String)>[];

  @override
  Future<OpenOutcome> open(String path) async {
    opened.add(path);
    return outcome;
  }

  @override
  Future<void> share(String path, {required String subject}) async => shared.add((path, subject));
}

/// Téléchargement simulé (pas de vrai fichier dans les tests d'écran) ; `gate` le fait attendre.
class FakeDownloader implements DocumentDownloader {
  final requests = <(String, String)>[];
  Completer<void>? gate;
  ApiFailure? failure;

  @override
  Future<File> download(String path, String fileName) async {
    requests.add((path, fileName));
    await gate?.future;
    if (failure != null) throw failure!;
    return File('/privé/documents/$fileName');
  }
}

Future<void> pumpDetail(
  WidgetTester tester,
  FakeHomeBackend backend, {
  required FakeDocumentActions actions,
  required FakeDownloader downloader,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = itelPhysicalSize;
  tester.view.devicePixelRatio = itelPixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(
    initialLocation: Routes.bill(101),
    routes: [
      GoRoute(
        path: Routes.billPath,
        builder: (context, state) =>
            BillDetailScreen(billId: int.parse(state.pathParameters['billId']!)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
        homeClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12, 9)),
        documentActionsProvider.overrideWithValue(actions),
        documentDownloaderProvider.overrideWithValue(downloader),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const fileName = 'facture-20261103000127.pdf';

void main() {
  test('nom de fichier sûr : « facture-20261103000127.pdf »', () {
    expect(documentFileName('facture', '20261103000127'), fileName);
    expect(documentFileName('recu', 'EP-2026/000123 ../x'), 'recu-EP-2026000123x.pdf');
  });

  test('le PDF n’est JAMAIS mis en cache hors ligne', () {
    expect(isCacheable('/bills/101/pdf'), isFalse);
    expect(neverCachedRoutes, contains('/bills/{bill_id}/pdf'));
  });

  test('téléchargement réel : octets de l’API enregistrés dans le dossier privé', () async {
    final backend = FakeHomeBackend();
    final directory = await Directory.systemTemp.createTemp('elecpay_pdf');
    addTearDown(() => directory.delete(recursive: true));
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
        documentsDirectoryProvider.overrideWithValue(() async => directory),
      ],
    );
    addTearDown(container.dispose);
    final file = await container
        .read(documentDownloaderProvider)
        .download('/bills/101/pdf', fileName);
    expect(file.path, '${directory.path}/$fileName');
    expect(await file.readAsString(), '%PDF-1.4 facture de démonstration');
    expect(backend.requestsTo('/bills/101/pdf'), hasLength(1));
  });

  test('téléchargement refusé (404) : l’erreur de l’API remonte, aucun fichier', () async {
    final backend = FakeHomeBackend()..billDetails.clear();
    final directory = await Directory.systemTemp.createTemp('elecpay_pdf');
    addTearDown(() => directory.delete(recursive: true));
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        ...backend.overrides(),
        documentsDirectoryProvider.overrideWithValue(() async => directory),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(documentDownloaderProvider).download('/bills/101/pdf', fileName),
      throwsA(isA<ApiRejected>().having((f) => f.message, 'message', 'Facture introuvable.')),
    );
    expect(directory.listSync(), isEmpty);
  });

  testWidgets('« PDF » : téléchargé puis ouvert dans le lecteur du téléphone', (tester) async {
    final actions = FakeDocumentActions();
    final downloader = FakeDownloader();
    await pumpDetail(tester, FakeHomeBackend(), actions: actions, downloader: downloader);
    await tester.tap(find.byKey(const Key('bill.pdf')));
    await settle(tester);
    expect(downloader.requests, [('/bills/101/pdf', fileName)]);
    expect(actions.opened, ['/privé/documents/$fileName']);
    expect(actions.shared, isEmpty);
  });

  testWidgets('« Partager » (en haut) : téléchargé puis partagé', (tester) async {
    final actions = FakeDocumentActions();
    final downloader = FakeDownloader();
    await pumpDetail(tester, FakeHomeBackend(), actions: actions, downloader: downloader);
    await tester.tap(find.byKey(const Key('bill.share')));
    await settle(tester);
    expect(actions.shared, [('/privé/documents/$fileName', 'Facture ElecPay 20261103000127')]);
    expect(actions.opened, isEmpty);
  });

  testWidgets('aucun lecteur PDF : message, et « Partager » à la place', (tester) async {
    final actions = FakeDocumentActions()..outcome = OpenOutcome.noApp;
    await pumpDetail(tester, FakeHomeBackend(), actions: actions, downloader: FakeDownloader());
    await tester.tap(find.byKey(const Key('bill.pdf')));
    await settle(tester);
    expect(find.text('Aucune application pour ouvrir le PDF.'), findsOneWidget);
    await tester.tap(find.text('Partager'));
    await settle(tester);
    expect(actions.shared, hasLength(1));
  });

  testWidgets('erreur de l’API : son message et la référence', (tester) async {
    final downloader = FakeDownloader()
      ..failure = const ServerUnavailable(statusCode: 503, reference: 'r-pdf');
    await pumpDetail(
      tester,
      FakeHomeBackend(),
      actions: FakeDocumentActions(),
      downloader: downloader,
    );
    await tester.tap(find.byKey(const Key('bill.pdf')));
    await settle(tester);
    expect(find.textContaining('Référence : r-pdf'), findsOneWidget);
  });

  testWidgets('double toucher : un seul téléchargement', (tester) async {
    final downloader = FakeDownloader()..gate = Completer<void>();
    final actions = FakeDocumentActions();
    await pumpDetail(tester, FakeHomeBackend(), actions: actions, downloader: downloader);
    await tester.tap(find.byKey(const Key('bill.pdf')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bill.pdf')), warnIfMissed: false);
    await tester.tap(find.byKey(const Key('bill.share')));
    await tester.pump();
    downloader.gate!.complete();
    await settle(tester);
    expect(downloader.requests, hasLength(1));
    expect(actions.opened, hasLength(1));
    expect(actions.shared, isEmpty);
  });

  testWidgets('hors ligne : PDF et Partager désactivés, rien n’est téléchargé', (tester) async {
    final backend = FakeHomeBackend();
    final downloader = FakeDownloader();
    final actions = FakeDocumentActions();
    await pumpDetail(tester, backend, actions: actions, downloader: downloader);
    await tester.pumpWidget(const SizedBox());
    backend.down.add('/bills');
    await pumpDetail(tester, backend, actions: actions, downloader: downloader);
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bill.pdf')), warnIfMissed: false);
    await tester.tap(find.byKey(const Key('bill.share')), warnIfMissed: false);
    await settle(tester);
    expect(downloader.requests, isEmpty);
    expect(tester.widget<IconButton>(find.byKey(const Key('bill.share'))).onPressed, isNull);
  });

  testWidgets('payée, hors ligne : « Connexion nécessaire pour le PDF »', (tester) async {
    final backend = FakeHomeBackend()
      ..billDetails[101] = FakeHomeBackend.billDetail(
        101,
        status: BillStatuses.paid,
        canPay: false,
      );
    final actions = FakeDocumentActions();
    final downloader = FakeDownloader();
    await pumpDetail(tester, backend, actions: actions, downloader: downloader);
    expect(find.byKey(const Key('bill.pdf')), findsOneWidget, reason: 'le PDF reste proposé');
    await tester.pumpWidget(const SizedBox());
    backend.down.add('/bills');
    await pumpDetail(tester, backend, actions: actions, downloader: downloader);
    expect(find.text('Connexion nécessaire pour le PDF'), findsOneWidget);
  });

  group('règle 2 : bas de l’écran (PDF + Payer) à 100, 130 et 200 %', () {
    for (final scale in textScales) {
      testWidgets('rien ne déborde à ${(scale * 100).round()} %', (tester) async {
        await pumpDetail(
          tester,
          FakeHomeBackend(),
          actions: FakeDocumentActions(),
          downloader: FakeDownloader(),
          textScale: scale,
        );
        expect(find.byKey(const Key('bill.pdf')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
