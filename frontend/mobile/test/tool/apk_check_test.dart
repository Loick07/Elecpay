import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/apk_check.dart';

/// Extraits réels de `aapt2 dump xmltree` sur les APK construits le 16/11/2026.
const _attribute = 'A: http://schemas.android.com/apk/res/android:usesCleartextTraffic(0x010104ec)';

void main() {
  test('APK release : HTTP en clair interdit', () {
    expect(cleartextFromXmlTree('E: application\n        $_attribute=false\n'), isFalse);
  });

  test('APK debug / profile : HTTP en clair permis', () {
    const debuggable = 'A: http://schemas.android.com/apk/res/android:debuggable(0x0101000f)=true';
    expect(cleartextFromXmlTree('$debuggable\n$_attribute=true\n'), isTrue);
  });

  test('attribut absent : signalé (null), jamais pris pour « interdit »', () {
    expect(cleartextFromXmlTree('E: application\n'), isNull);
  });

  group('sauvegarde Android (allowBackup)', () {
    const backup = 'A: http://schemas.android.com/apk/res/android:allowBackup(0x01010280)';

    test('false → lu comme interdit', () {
      expect(allowBackupFromXmlTree('$backup=false\n$_attribute=false\n'), isFalse);
    });

    test('true → lu comme autorisé', () {
      expect(allowBackupFromXmlTree('$backup=true\n'), isTrue);
    });

    test('absent → null (Android sauvegarderait par défaut : refusé par l’outil)', () {
      expect(allowBackupFromXmlTree('$_attribute=false\n'), isNull);
    });
  });

  group('règles d’extraction de données (Android 12+)', () {
    /// Fichier compilé, au format de `aapt2 dump xmltree` (relevé sur l'APK du 16/11/2026).
    String compiled({Map<String, List<String>>? domains, String path = '.', bool include = false}) {
      final out = StringBuffer('E: data-extraction-rules (line=6)\n');
      var line = 7;
      for (final section in extractionSections) {
        out.writeln('    E: $section (line=${line++})');
        for (final domain in domains?[section] ?? dataDomains) {
          out
            ..writeln('        E: exclude (line=${line++})')
            ..writeln('          A: domain="$domain" (Raw: "$domain")')
            ..writeln('          A: path="$path" (Raw: "$path")');
        }
        if (include) {
          out
            ..writeln('        E: include (line=${line++})')
            ..writeln('          A: domain="file" (Raw: "file")');
        }
      }
      return out.toString();
    }

    test('tout exclu dans les deux sections → conforme', () {
      expect(extractionRulesProblems(compiled()), isEmpty);
    });

    test('un domaine oublié dans le transfert d’appareil → signalé', () {
      final rules = compiled(
        domains: {
          'cloud-backup': dataDomains,
          'device-transfer': dataDomains.where((d) => d != 'device_file').toList(),
        },
      );
      expect(extractionRulesProblems(rules), [
        '<device-transfer> n’exclut pas en entier : device_file',
      ]);
    });

    test('exclusion partielle (un sous-dossier seulement) → signalée', () {
      expect(extractionRulesProblems(compiled(path: 'cache')), hasLength(2));
    });

    test('une inclusion → signalée', () {
      expect(extractionRulesProblems(compiled(include: true)), contains(contains('include')));
    });

    test('section absente → signalée', () {
      final cloudOnly = compiled().split('    E: device-transfer').first;
      expect(extractionRulesProblems(cloudOnly), ['section <device-transfer> absente']);
    });

    test('référence du manifeste et chemin du fichier compilé', () {
      const manifest =
          'A: http://schemas.android.com/apk/res/android:dataExtractionRules(0x0101063e)=@0x7f0e0000';
      expect(dataExtractionRulesId(manifest), '0x7f0e0000');
      expect(dataExtractionRulesId('E: application'), isNull);
      const resources =
          '    resource 0x7f0e0000 xml/data_extraction_rules\n'
          '      () (file) res/xml/data_extraction_rules.xml type=XML\n';
      expect(resourceFilePath(resources, '0x7f0e0000'), 'res/xml/data_extraction_rules.xml');
      expect(resourceFilePath(resources, '0x7f0e0001'), isNull);
    });
  });

  group('mot de passe de démo', () {
    test('même valeur que celui des comptes de démo du backend', () {
      final dataset = File('../../backend/app/simulators/demo_dataset.py').readAsStringSync();
      expect(dataset, contains('DEMO_PASSWORD = "$demoPassword"'));
    });

    /// Un petit APK (archive zip) avec les fichiers donnés.
    List<int> apk(Map<String, String> files) {
      final archive = Archive();
      for (final entry in files.entries) {
        archive.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value)));
      }
      return ZipEncoder().encode(archive);
    }

    test('trouvé dans n’importe quel fichier (code, ressources, fichiers embarqués)', () {
      final bytes = apk({
        'lib/armeabi-v7a/libapp.so': 'xx${demoPassword}xx',
        'assets/flutter_assets/assets/config.json': '{"password": "$demoPassword"}',
        'classes.dex': 'rien',
      });
      expect(filesContaining(bytes, demoPassword), [
        'lib/armeabi-v7a/libapp.so',
        'assets/flutter_assets/assets/config.json',
      ]);
    });

    test('absent → aucune entrée', () {
      expect(filesContaining(apk({'lib/x86_64/libapp.so': 'Demo2025!'}), demoPassword), isEmpty);
    });
  });

  test('taille affichée en Mo, à la française', () {
    expect(formatSize(15099494), '14,4 Mo');
  });
}
