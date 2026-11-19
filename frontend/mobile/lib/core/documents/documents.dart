import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../session/session_providers.dart';

// PDF d'une facture (F5) ou d'un reçu (F6) : téléchargé à la demande dans le dossier PRIVÉ de
// l'application (jamais en cache hors ligne, jamais dans le stockage partagé : aucune autorisation
// Android), puis ouvert dans le lecteur du téléphone (open_filex) ou partagé (share_plus).
// Décision D5.1 de DECOUPAGES.md.

/// Résultat de l'ouverture d'un document.
enum OpenOutcome {
  opened,

  /// Aucun lecteur PDF sur le téléphone : on propose de partager à la place.
  noApp,
  failed,
}

/// Ouvrir et partager un fichier déjà enregistré (remplacé par un faux dans les tests).
abstract interface class DocumentActions {
  Future<OpenOutcome> open(String path);
  Future<void> share(String path, {required String subject});
}

class SystemDocumentActions implements DocumentActions {
  const SystemDocumentActions();

  @override
  Future<OpenOutcome> open(String path) async {
    final result = await OpenFilex.open(path, type: 'application/pdf');
    return switch (result.type) {
      ResultType.done => OpenOutcome.opened,
      ResultType.noAppToOpen => OpenOutcome.noApp,
      _ => OpenOutcome.failed,
    };
  }

  @override
  Future<void> share(String path, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        subject: subject,
      ),
    );
  }
}

final documentActionsProvider = Provider<DocumentActions>((ref) => const SystemDocumentActions());

/// Dossier où ranger les PDF téléchargés (dossier temporaire PRIVÉ de l'application).
final documentsDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory('${(await getTemporaryDirectory()).path}/documents'),
);

/// Nom de fichier sûr : « facture-20261103000127.pdf » (seulement lettres, chiffres et tirets).
String documentFileName(String prefix, String reference) =>
    '$prefix-${reference.replaceAll(RegExp('[^A-Za-z0-9-]'), '')}.pdf';

/// Télécharge `path` (route de l'API qui renvoie un PDF) et l'enregistre sous `fileName`.
/// Les erreurs de l'API remontent telles quelles (`ApiFailure` : message et référence).
class DocumentDownloader {
  DocumentDownloader(this._ref);

  final Ref _ref;

  Future<File> download(String path, String fileName) async {
    final bytes = await _ref.read(authenticatedApiProvider).getBytes(path);
    final directory = await _ref.read(documentsDirectoryProvider)();
    await directory.create(recursive: true);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

final documentDownloaderProvider = Provider<DocumentDownloader>(DocumentDownloader.new);
