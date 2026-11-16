// Vérifie un APK construit : affiche sa taille et contrôle, dans le manifeste COMPILÉ (après fusion
// des manifestes main / debug / profile) :
// - le réglage « HTTP en clair » (attendu : true en debug / profile, false en release) ;
// - l'absence de sauvegarde Android (`allowBackup="false"`, exigé pour toutes les versions) ;
// - les règles d'extraction de données (Android 12+) : le manifeste y fait référence, et le fichier
//   compilé exclut TOUTES les données, en sauvegarde cloud comme en transfert d'appareil à appareil.
//
// Usage (depuis frontend/mobile) :
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-release.apk --cleartext=false
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-debug.apk --cleartext=true
//
// Lit l'APK avec `aapt2` (SDK Android : ANDROID_HOME, ANDROID_SDK_ROOT ou
// %LOCALAPPDATA%\Android\sdk). Code de sortie 1 si une règle n'est pas respectée.
import 'dart:io';

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

/// Taille lisible, en Mo avec une décimale (ex. « 14,4 Mo »).
String formatSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';

String? findAapt2() {
  final roots = [
    Platform.environment['ANDROID_HOME'],
    Platform.environment['ANDROID_SDK_ROOT'],
    if (Platform.environment['LOCALAPPDATA'] case final local?) '$local/Android/sdk',
  ].whereType<String>();
  final exe = Platform.isWindows ? 'aapt2.exe' : 'aapt2';
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

void main(List<String> args) {
  final expected = args.where((a) => a.startsWith('--cleartext=')).map((a) => a.split('=')[1]);
  final paths = args.where((a) => !a.startsWith('--')).toList();
  if (paths.length != 1 || expected.length != 1 || !{'true', 'false'}.contains(expected.first)) {
    stderr.writeln('Usage : dart run tool/apk_check.dart <fichier.apk> --cleartext=true|false');
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
  final wanted = expected.first == 'true';
  stdout.writeln('HTTP en clair (usesCleartextTraffic) : ${cleartext ?? 'absent'}');
  if (cleartext != wanted) error('usesCleartextTraffic devrait valoir $wanted dans cet APK.');

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

  if (!ok) exit(1);
  stdout.writeln('OK');
}
