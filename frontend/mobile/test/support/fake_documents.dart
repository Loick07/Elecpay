import 'dart:async';
import 'dart:io';

import 'package:elecpay/core/documents/documents.dart';
import 'package:elecpay/core/network/api_failure.dart';

// PDF simulés (factures F5, reçus F6) : aucun fichier réel, aucune autre application ouverte.

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
