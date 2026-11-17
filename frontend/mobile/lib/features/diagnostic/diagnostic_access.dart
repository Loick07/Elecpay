import 'package:flutter/foundation.dart';

/// Page Diagnostic : versions debug et profile SEULEMENT, JAMAIS en release.
///
/// C'est une CONSTANTE : en release (`kReleaseMode` vrai), tout code placé sous
/// `if (diagnosticsEnabled)` est retiré par le compilateur, et la page n'existe pas dans l'APK.
/// Preuve en CI : `tool/apk_check.dart` vérifie que [diagnosticMarker] est absent du code compilé
/// de l'APK release.
const diagnosticsEnabled = !kReleaseMode;

/// Marque unique de la page, cherchée dans le code compilé de l'APK (doit être absente en release).
/// Même valeur que `diagnosticMarker` dans tool/apk_check.dart (un test le vérifie).
const diagnosticMarker = 'ELECPAY-DIAGNOSTIC-PAGE-7F3A';
