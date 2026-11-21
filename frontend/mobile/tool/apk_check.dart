// Vérifie un APK construit : affiche sa taille et contrôle, dans le manifeste COMPILÉ (après fusion
// des manifestes main / debug / profile) :
// - le réglage « HTTP en clair » (attendu : true en debug / profile, false en release) ;
// - l'absence de sauvegarde Android (`allowBackup="false"`, exigé pour toutes les versions) ;
// - les autorisations : seulement celles de la liste blanche (`allowedPermissions`), jamais
//   `REQUEST_INSTALL_PACKAGES` ni l'accès aux fichiers (toutes les versions) ;
// - les règles d'extraction de données (Android 12+) : le manifeste y fait référence, et le fichier
//   compilé exclut TOUTES les données, en sauvegarde cloud comme en transfert d'appareil à appareil ;
// - avec `--diagnostic=absent` : la page Diagnostic n'est PAS dans le code compilé (release) ;
// - avec `--demo-password=absent` : le mot de passe de démo n'est dans AUCUN fichier de l'APK ;
// - avec `--lucide=reduced` : la police des icônes est réduite aux seules icônes utilisées ;
// - avec `--launcher-icon=custom` : AUCUNE icône Flutter par défaut dans l'APK (pixels comparés),
//   et le nom affiché sous l'icône est « ElecPay ».
// - avec `--api-url=https://…` (F10.4) : l'adresse de l'API donnée au build
//   (`--dart-define=API_BASE_URL`) est en https et se trouve dans le code Dart compilé ;
// - avec `--signature=release` (F10.4) : l'APK n'est PAS signé avec la clé de débogage d'Android
//   (`apksigner`, dans les build-tools du SDK) ; `--signature=debug` sert de contre-épreuve.
//
// Usage (depuis frontend/mobile) :
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-release.apk \
//     --cleartext=false --diagnostic=absent --demo-password=absent
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-profile.apk \
//     --cleartext=true --diagnostic=present --demo-password=present
//
// Lit l'APK avec `aapt2` (SDK Android : ANDROID_HOME, ANDROID_SDK_ROOT ou
// %LOCALAPPDATA%\Android\sdk). Code de sortie 1 si une règle n'est pas respectée.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

/// Tous les domaines de stockage d'Android : chacun doit être exclu, dans les deux sections.
const dataDomains = [
  'root',
  'file',
  'database',
  'sharedpref',
  'external',
  'device_root',
  'device_file',
  'device_database',
  'device_sharedpref',
];

/// Les deux voies par lesquelles des données peuvent quitter le téléphone (Android 12+).
const extractionSections = ['cloud-backup', 'device-transfer'];

/// Valeur de `android:usesCleartextTraffic` dans la sortie de `aapt2 dump xmltree`,
/// ou `null` si l'attribut est absent (Android l'autorise alors par défaut jusqu'à l'API 27).
bool? cleartextFromXmlTree(String xmlTree) {
  final match = RegExp(r'usesCleartextTraffic\([^)]*\)=(true|false)').firstMatch(xmlTree);
  return match == null ? null : match.group(1) == 'true';
}

/// Valeur de `android:allowBackup`, ou `null` si absent (Android sauvegarde alors l'application).
bool? allowBackupFromXmlTree(String xmlTree) {
  final match = RegExp(r'allowBackup\([^)]*\)=(true|false)').firstMatch(xmlTree);
  return match == null ? null : match.group(1) == 'true';
}

/// Autorisations Android déclarées (`uses-permission`, `uses-permission-sdk-23`) dans la sortie de
/// `aapt2 dump xmltree` du manifeste compilé.
List<String> permissionsFromXmlTree(String manifestTree) {
  final permissions = <String>[];
  var inPermission = false;
  for (final line in manifestTree.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('E: ')) {
      inPermission = RegExp(r'^E: uses-permission(-sdk-23)?\b').hasMatch(trimmed);
      continue;
    }
    if (!inPermission) continue;
    final name = RegExp(r':name\([^)]*\)="([^"]+)"').firstMatch(trimmed)?.group(1);
    if (name != null) {
      permissions.add(name);
      inPermission = false;
    }
  }
  return permissions;
}

/// Autorisations PERMISES dans l'APK (liste blanche, décision de Loick du 19/11/2026 : aucune
/// autorisation sensible). Toute autre autorisation fait échouer le contrôle : en ajouter une
/// demande une décision. `<paquet>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` est propre à
/// l'application (ajoutée par AndroidX, protège ses récepteurs internes).
const allowedPermissions = {
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
};

/// Autorisations nommées dans le message d'erreur, en plus de la liste blanche (exemples connus
/// ajoutés par des paquets : installation d'APK, accès aux fichiers…).
const knownSensitivePermissions = {
  'android.permission.REQUEST_INSTALL_PACKAGES',
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.MANAGE_EXTERNAL_STORAGE',
  'android.permission.QUERY_ALL_PACKAGES',
};

/// Autorisations refusées parmi `permissions` (celles hors de la liste blanche).
List<String> forbiddenPermissions(Iterable<String> permissions) => [
  for (final p in permissions)
    if (!allowedPermissions.contains(p) && !p.endsWith('.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'))
      p,
];

/// Identifiant de la ressource désignée par `android:dataExtractionRules` (ex. `0x7f0e0000`).
String? dataExtractionRulesId(String manifestTree) =>
    RegExp(r'dataExtractionRules\([^)]*\)=@(0x[0-9a-f]+)').firstMatch(manifestTree)?.group(1);

/// Chemin, dans l'APK, du fichier de la ressource `id` (sortie de `aapt2 dump resources`).
/// En release, Android peut raccourcir ce chemin : on le lit donc au lieu de le deviner.
String? resourceFilePath(String resourcesDump, String id) {
  final lines = resourcesDump.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].contains('resource $id ')) continue;
    for (final next in lines.skip(i + 1).take(3)) {
      final file = RegExp(r'\(file\) (\S+)').firstMatch(next);
      if (file != null) return file.group(1);
    }
  }
  return null;
}

/// Problèmes des règles d'extraction compilées (sortie de `aapt2 dump xmltree`) ; vide = conforme.
///
/// Exigé : une section `cloud-backup` et une section `device-transfer`, chacune excluant chaque
/// domaine de [dataDomains] en entier (`path="."`), et AUCUNE inclusion.
List<String> extractionRulesProblems(String rulesTree) {
  final problems = <String>[];
  if (rulesTree.contains('E: include')) problems.add('une règle <include> est présente');

  // Découpe par élément : « E: nom » suivi de ses attributs « A: … ».
  final elements = rulesTree.split(RegExp(r'\n(?=\s*E: )'));
  String? section;
  final excluded = {for (final s in extractionSections) s: <String>{}};
  for (final element in elements) {
    final name = RegExp(r'E: ([\w-]+)').firstMatch(element)?.group(1);
    if (extractionSections.contains(name)) {
      section = name;
    } else if (name == 'exclude' && section != null) {
      final domain = RegExp(r'domain="([^"]*)"').firstMatch(element)?.group(1);
      final path = RegExp(r'path="([^"]*)"').firstMatch(element)?.group(1);
      if (domain != null && path == '.') excluded[section]!.add(domain);
    }
  }
  for (final s in extractionSections) {
    final missing = dataDomains.where((d) => !excluded[s]!.contains(d)).toList();
    if (!rulesTree.contains('E: $s')) {
      problems.add('section <$s> absente');
    } else if (missing.isNotEmpty) {
      problems.add('<$s> n’exclut pas en entier : ${missing.join(', ')}');
    }
  }
  return problems;
}

/// Marque unique de la page Diagnostic (même valeur que dans
/// lib/features/diagnostic/diagnostic_access.dart, vérifié par un test).
const diagnosticMarker = 'ELECPAY-DIAGNOSTIC-PAGE-7F3A';

/// Fichiers de l'APK qui contiennent le code Dart compilé : `libapp.so` (profile, release) ou
/// `kernel_blob.bin` (debug).
bool isDartCode(String entryName) =>
    entryName.endsWith('/libapp.so') || entryName.endsWith('kernel_blob.bin');

/// `needle` apparaît-il dans `haystack` ? (recherche d'octets, pour les gros fichiers compilés)
bool containsBytes(List<int> haystack, List<int> needle) {
  if (needle.isEmpty) return true;
  final first = needle.first;
  final last = haystack.length - needle.length;
  outer:
  for (var i = 0; i <= last; i++) {
    if (haystack[i] != first) continue;
    for (var j = 1; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

/// La page Diagnostic est-elle dans le code Dart de l'APK ? `null` si aucun code Dart trouvé.
bool? diagnosticInApk(List<int> apkBytes) {
  final archive = ZipDecoder().decodeBytes(apkBytes);
  final code = archive.files.where((f) => f.isFile && isDartCode(f.name)).toList();
  if (code.isEmpty) return null;
  final marker = ascii.encode(diagnosticMarker);
  return code.any((f) => containsBytes(f.readBytes()!, marker));
}

/// Mot de passe des comptes de démo (backend/app/simulators : un test vérifie qu'il est identique).
/// Il ne doit JAMAIS se trouver dans l'APK livré.
const demoPassword = 'Demo2026!';

/// Fichiers de l'APK (TOUS : code, ressources, fichiers embarqués) qui contiennent `text`.
List<String> filesContaining(List<int> apkBytes, String text) {
  final needle = utf8.encode(text);
  return [
    for (final file in ZipDecoder().decodeBytes(apkBytes).files)
      if (file.isFile && containsBytes(file.readBytes()!, needle)) file.name,
  ];
}

/// Police des icônes dans l'APK, et taille au-delà de laquelle elle n'a PAS été réduite par Flutter
/// aux seules icônes utilisées (entière : 999 164 octets ; réduite : quelques Ko).
const lucideAssetPath = 'assets/flutter_assets/assets/fonts/Lucide.ttf';
const lucideReducedMaxBytes = 100 * 1024;

/// Taille de la police Lucide dans l'APK, ou `null` si elle est absente.
int? lucideFontSize(List<int> apkBytes) {
  for (final file in ZipDecoder().decodeBytes(apkBytes).files) {
    if (file.name == lucideAssetPath) return file.size;
  }
  return null;
}

/// Empreinte des PIXELS d'une image PNG (RGBA, FNV-1a 64 bits), ou `null` si illisible.
///
/// Les pixels, pas le fichier : au build release, Android renomme les images (`res/9w.png`) et les
/// recompresse sans perte ; le fichier change, ses pixels non.
String? pngPixelHash(List<int> pngBytes) {
  final decoded = img.decodePng(Uint8List.fromList(pngBytes));
  if (decoded == null) return null;
  final pixels = decoded
      .convert(numChannels: 4, format: img.Format.uint8)
      .getBytes(order: img.ChannelOrder.rgba);
  var hash = 0xcbf29ce484222325;
  for (final byte in [...utf8.encode('${decoded.width}x${decoded.height}'), ...pixels]) {
    hash = (hash ^ byte) * 0x100000001b3;
  }
  // Entier signé de 64 bits : écrit en deux moitiés de 32 bits (16 chiffres hexadécimaux).
  String half(int value) => value.toRadixString(16).padLeft(8, '0');
  return half(hash >>> 32) + half(hash & 0xffffffff);
}

/// Pixels des 5 icônes Flutter par défaut (mipmap-mdpi → xxxhdpi/ic_launcher.png du modèle
/// `flutter create`, présentes dans le dépôt jusqu'au jalon F3). Aucune ne doit rester dans l'APK.
const flutterDefaultIconPixels = <String>{
  '903b50d1e304ee6b', // mdpi (48 × 48)
  '1eff73413af52a7f', // hdpi
  'b916c9a9716d3b18', // xhdpi
  '444dcc310796a8cc', // xxhdpi
  'bff436cd1ba419fb', // xxxhdpi (192 × 192)
};

/// Nom affiché sous l'icône de l'application.
const expectedLabel = 'ElecPay';

/// Images de l'APK dont les pixels sont ceux d'une icône Flutter par défaut.
List<String> flutterDefaultIcons(List<int> apkBytes) => [
  for (final file in ZipDecoder().decodeBytes(apkBytes).files)
    if (file.isFile &&
        file.name.endsWith('.png') &&
        flutterDefaultIconPixels.contains(pngPixelHash(file.readBytes()!)))
      file.name,
];

/// Fichiers de CODE DART de l'APK (libapp.so, kernel_blob.bin) qui contiennent `text`.
List<String> dartFilesContaining(List<int> apkBytes, String text) {
  final needle = utf8.encode(text);
  return [
    for (final file in ZipDecoder().decodeBytes(apkBytes).files)
      if (file.isFile && isDartCode(file.name) && containsBytes(file.readBytes()!, needle))
        file.name,
  ];
}

/// Certificat du premier signataire (`apksigner verify --print-certs`), ex. « CN=Android Debug,
/// O=Android, C=US », ou `null`.
String? signerCertificate(String printCerts) => RegExp(
  r'^Signer #1 certificate DN: (.*)$',
  multiLine: true,
).firstMatch(printCerts)?.group(1)?.trim();

/// Clé de débogage d'Android (créée par le SDK sur chaque PC) : jamais pour l'APK livré.
bool isDebugCertificate(String dn) => dn.contains('CN=Android Debug');

/// Nom affiché sous l'icône (`application-label` de `aapt2 dump badging`), ou `null`.
String? applicationLabel(String badging) =>
    RegExp(r"^application-label:'([^']*)'", multiLine: true).firstMatch(badging)?.group(1);

/// Taille lisible, en Mo avec une décimale (ex. « 14,4 Mo »).
String formatSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';

String? findAapt2() => findBuildTool(Platform.isWindows ? 'aapt2.exe' : 'aapt2');

String? findApksigner() => findBuildTool(Platform.isWindows ? 'apksigner.bat' : 'apksigner');

/// Outil `exe` des build-tools du SDK Android (version la plus récente qui l'a).
String? findBuildTool(String exe) {
  final roots = [
    Platform.environment['ANDROID_HOME'],
    Platform.environment['ANDROID_SDK_ROOT'],
    if (Platform.environment['LOCALAPPDATA'] case final local?) '$local/Android/sdk',
  ].whereType<String>();
  for (final root in roots) {
    final buildTools = Directory('$root/build-tools');
    if (!buildTools.existsSync()) continue;
    final versions = buildTools.listSync().whereType<Directory>().toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // la plus récente d'abord
    for (final version in versions) {
      final candidate = File('${version.path}/$exe');
      if (candidate.existsSync()) return candidate.path;
    }
  }
  return null;
}

String _aapt2(String aapt2, List<String> args) {
  final result = Process.runSync(aapt2, args);
  if (result.exitCode != 0) {
    stderr.writeln('aapt2 a échoué (${args.join(' ')}) : ${result.stderr}');
    exit(2);
  }
  return result.stdout as String;
}

const _usage =
    'Usage : dart run tool/apk_check.dart <fichier.apk> --cleartext=true|false '
    '[--diagnostic=absent|present] [--demo-password=absent|present] [--lucide=reduced] '
    '[--launcher-icon=custom] [--api-url=https://…] [--signature=release|debug]';

void main(List<String> args) {
  String? option(String name) => args
      .where((a) => a.startsWith('--$name='))
      .map((a) => a.substring('--$name='.length))
      .lastOrNull;
  bool validPresence(String? value) => value == null || {'absent', 'present'}.contains(value);
  final cleartextOption = option('cleartext');
  final diagnosticOption = option('diagnostic');
  final demoPasswordOption = option('demo-password');
  final lucideOption = option('lucide');
  final launcherIconOption = option('launcher-icon');
  final apiUrlOption = option('api-url');
  final signatureOption = option('signature');
  final paths = args.where((a) => !a.startsWith('--')).toList();
  if (paths.length != 1 ||
      !{'true', 'false'}.contains(cleartextOption) ||
      !validPresence(diagnosticOption) ||
      !validPresence(demoPasswordOption) ||
      (lucideOption != null && lucideOption != 'reduced') ||
      (launcherIconOption != null && launcherIconOption != 'custom') ||
      (signatureOption != null && !{'release', 'debug'}.contains(signatureOption))) {
    stderr.writeln(_usage);
    exit(2);
  }
  final apk = File(paths.single);
  if (!apk.existsSync()) {
    stderr.writeln('APK introuvable : ${apk.path}');
    exit(2);
  }
  final aapt2 = findAapt2();
  if (aapt2 == null) {
    stderr.writeln('aapt2 introuvable : définir ANDROID_HOME (SDK Android avec build-tools).');
    exit(2);
  }

  stdout.writeln('APK : ${apk.path}');
  stdout.writeln('Taille : ${formatSize(apk.lengthSync())} (${apk.lengthSync()} octets)');

  final manifest = _aapt2(aapt2, ['dump', 'xmltree', '--file', 'AndroidManifest.xml', apk.path]);
  var ok = true;
  void error(String message) {
    stderr.writeln('ERREUR : $message');
    ok = false;
  }

  final cleartext = cleartextFromXmlTree(manifest);
  final wanted = cleartextOption == 'true';
  stdout.writeln('HTTP en clair (usesCleartextTraffic) : ${cleartext ?? 'absent'}');
  if (cleartext != wanted) error('usesCleartextTraffic devrait valoir $wanted dans cet APK.');

  // Toujours vérifié : aucune autorisation sensible (liste blanche).
  final permissions = permissionsFromXmlTree(manifest);
  stdout.writeln('Autorisations : ${permissions.isEmpty ? 'aucune' : permissions.join(', ')}');
  final forbidden = forbiddenPermissions(permissions);
  if (forbidden.isNotEmpty) {
    final sensitive = forbidden.where(knownSensitivePermissions.contains);
    error(
      'autorisations non permises dans l’APK : ${forbidden.join(', ')}'
      '${sensitive.isEmpty ? '' : ' (dont sensibles connues : ${sensitive.join(', ')})'}. '
      'Les retirer (tools:node="remove" dans le manifeste) ou faire décider Loick.',
    );
  }

  // Toujours interdit, quelle que soit la version : jetons et cache hors des sauvegardes.
  final backup = allowBackupFromXmlTree(manifest);
  stdout.writeln('Sauvegarde Android (allowBackup) : ${backup ?? 'absent'}');
  if (backup != false) {
    error('allowBackup doit valoir false (jetons et cache hors des sauvegardes).');
  }

  final rulesId = dataExtractionRulesId(manifest);
  if (rulesId == null) {
    error('le manifeste ne fait pas référence à des règles dataExtractionRules.');
  } else {
    final resources = _aapt2(aapt2, ['dump', 'resources', apk.path]);
    final rulesPath = resourceFilePath(resources, rulesId);
    if (rulesPath == null) {
      error('fichier des règles dataExtractionRules ($rulesId) introuvable dans l’APK.');
    } else {
      final rules = _aapt2(aapt2, ['dump', 'xmltree', '--file', rulesPath, apk.path]);
      final problems = extractionRulesProblems(rules);
      stdout.writeln(
        'Extraction de données ($rulesPath) : '
        '${problems.isEmpty ? 'tout est exclu (cloud et appareil à appareil)' : 'NON CONFORME'}',
      );
      for (final problem in problems) {
        error('dataExtractionRules : $problem.');
      }
    }
  }

  // Page Diagnostic : `absent` attendu en release (retirée par le compilateur), `present` sert de
  // contre-épreuve sur un APK profile (preuve que la recherche fonctionne).
  if (diagnosticOption != null) {
    final found = diagnosticInApk(apk.readAsBytesSync());
    stdout.writeln(
      'Page Diagnostic dans le code compilé : '
      '${found == null ? 'code Dart introuvable' : (found ? 'présente' : 'absente')}',
    );
    if (found == null) {
      error('aucun code Dart (libapp.so / kernel_blob.bin) trouvé dans l’APK.');
    } else if (found != (diagnosticOption == 'present')) {
      error('la page Diagnostic devrait être $diagnosticOption dans cet APK.');
    }
  }

  // Mot de passe de démo : `absent` attendu en release (cherché dans TOUS les fichiers de l'APK),
  // `present` sert de contre-épreuve sur un APK profile (la page Diagnostic le préremplit).
  if (demoPasswordOption != null) {
    final files = filesContaining(apk.readAsBytesSync(), demoPassword);
    stdout.writeln(
      'Mot de passe de démo dans l’APK : '
      '${files.isEmpty ? 'absent' : 'présent (${files.join(', ')})'}',
    );
    if (files.isNotEmpty != (demoPasswordOption == 'present')) {
      error('le mot de passe de démo devrait être $demoPasswordOption dans cet APK.');
    }
  }

  // Police des icônes : réduite par Flutter aux seules icônes utilisées (sinon +449 Ko : arrive si
  // aucune icône Lucide n'est utilisée par le code release, mesuré le 17/11/2026).
  if (lucideOption == 'reduced') {
    final size = lucideFontSize(apk.readAsBytesSync());
    stdout.writeln(
      'Police Lucide dans l’APK : ${size == null ? 'absente' : '$size octets'} '
      '(réduite si moins de $lucideReducedMaxBytes)',
    );
    if (size == null) {
      error('police Lucide absente de l’APK ($lucideAssetPath).');
    } else if (size >= lucideReducedMaxBytes) {
      error('police Lucide NON réduite ($size octets) : aucune icône utilisée en release ?');
    }
  }

  // Icône de l'application : celle d'ElecPay, jamais l'icône Flutter du modèle `flutter create`.
  if (launcherIconOption == 'custom') {
    final defaults = flutterDefaultIcons(apk.readAsBytesSync());
    stdout.writeln(
      'Icône Flutter par défaut dans l’APK : '
      '${defaults.isEmpty ? 'absente' : 'PRÉSENTE (${defaults.join(', ')})'}',
    );
    if (defaults.isNotEmpty) {
      error('l’icône Flutter par défaut est encore dans l’APK : relancer flutter_launcher_icons.');
    }
    final label = applicationLabel(_aapt2(aapt2, ['dump', 'badging', apk.path]));
    stdout.writeln('Nom sous l’icône : ${label ?? 'absent'}');
    if (label != expectedLabel) error('le nom affiché devrait être « $expectedLabel ».');
  }

  // Adresse de l'API (F10.4) : https, et bien celle compilée dans l'APK (`--dart-define`).
  if (apiUrlOption != null) {
    if (!apiUrlOption.startsWith('https://')) {
      error('--api-url doit être en https:// (« $apiUrlOption ») : la version livrée l’exige.');
    } else {
      final files = dartFilesContaining(apk.readAsBytesSync(), apiUrlOption);
      stdout.writeln(
        'Adresse de l’API dans le code compilé : '
        '${files.isEmpty ? 'ABSENTE' : '$apiUrlOption (${files.join(', ')})'}',
      );
      if (files.isEmpty) {
        error('l’APK n’a pas été construit avec --dart-define=API_BASE_URL=$apiUrlOption.');
      }
    }
  }

  // Signature (F10.4) : la clé de l'APK livré, jamais la clé de débogage d'Android.
  if (signatureOption != null) {
    final apksigner = findApksigner();
    if (apksigner == null) {
      stderr.writeln(
        'apksigner introuvable : définir ANDROID_HOME (SDK Android avec build-tools).',
      );
      exit(2);
    }
    final result = Process.runSync(apksigner, [
      'verify',
      '--print-certs',
      apk.path,
    ], runInShell: Platform.isWindows);
    final dn = result.exitCode == 0 ? signerCertificate(result.stdout as String) : null;
    stdout.writeln('Signature : ${dn ?? 'illisible ou invalide'}');
    if (dn == null) {
      error(
        'signature de l’APK illisible : $apksigner (code ${result.exitCode}) '
        '| sortie : ${result.stdout} | erreurs : ${result.stderr}',
      );
    } else if (isDebugCertificate(dn) != (signatureOption == 'debug')) {
      error(
        signatureOption == 'release'
            ? 'APK signé avec la clé de DÉBOGAGE : créer la clé de l’APK livré (docs/LIVRAISON.md).'
            : 'APK signé avec une autre clé que celle de débogage.',
      );
    }
  }

  if (!ok) exit(1);
  stdout.writeln('OK');
}
