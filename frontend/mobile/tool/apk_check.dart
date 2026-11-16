// Vérifie un APK construit : affiche sa taille et contrôle le réglage « HTTP en clair »
// lu dans le manifeste COMPILÉ (après fusion des manifestes main / debug / profile).
//
// Usage (depuis frontend/mobile) :
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-release.apk --cleartext=false
//   dart run tool/apk_check.dart build/app/outputs/flutter-apk/app-debug.apk --cleartext=true
//
// Lit le manifeste avec `aapt2` (SDK Android : ANDROID_HOME, ANDROID_SDK_ROOT ou
// %LOCALAPPDATA%\Android\sdk). Code de sortie 1 si le réglage n'est pas celui attendu.
import 'dart:io';

/// Valeur de `android:usesCleartextTraffic` dans la sortie de `aapt2 dump xmltree`,
/// ou `null` si l'attribut est absent (Android l'autorise alors par défaut jusqu'à l'API 27).
bool? cleartextFromXmlTree(String xmlTree) {
  final match = RegExp(r'usesCleartextTraffic\([^)]*\)=(true|false)').firstMatch(xmlTree);
  return match == null ? null : match.group(1) == 'true';
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

  final dump = Process.runSync(aapt2, [
    'dump',
    'xmltree',
    '--file',
    'AndroidManifest.xml',
    apk.path,
  ]);
  if (dump.exitCode != 0) {
    stderr.writeln('aapt2 a échoué : ${dump.stderr}');
    exit(2);
  }
  final cleartext = cleartextFromXmlTree(dump.stdout as String);
  final wanted = expected.first == 'true';
  stdout.writeln('HTTP en clair (usesCleartextTraffic) : ${cleartext ?? 'absent'}');
  if (cleartext != wanted) {
    stderr.writeln('ERREUR : usesCleartextTraffic devrait valoir $wanted dans cet APK.');
    exit(1);
  }
  stdout.writeln('OK');
}
