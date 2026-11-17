import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licences des polices EMBARQUÉES (elles ne viennent pas d'un paquet, Flutter ne les connaît pas) :
/// fichiers de assets/fonts/, affichés dans l'écran des licences de l'application.
const fontLicenses = <String, String>{
  'Lucide (icônes)': 'assets/fonts/LICENSE-Lucide.txt',
  'Poppins': 'assets/fonts/OFL-Poppins.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
};

/// À appeler une fois au démarrage (`main`). Le texte n'est lu qu'à l'ouverture de l'écran des
/// licences.
void registerFontLicenses([AssetBundle? bundle]) {
  final assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([name], await assets.loadString(path));
    }
  });
}
