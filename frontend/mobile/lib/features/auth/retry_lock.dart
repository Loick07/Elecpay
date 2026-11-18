import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/format/dates.dart';

/// Blocage après « trop de tentatives » (429) : le bouton reste désactivé et affiche le temps
/// restant (« Réessayer dans 2:05 »), seconde par seconde. Commun aux écrans de connexion,
/// d'inscription et de mot de passe oublié.
class RetryLock extends ChangeNotifier {
  /// Délai quand l'API ne précise pas le sien (429 sans `retry_after_seconds`).
  static const defaultWait = Duration(seconds: 60);

  int _seconds = 0;
  Timer? _timer;

  bool get locked => _seconds > 0;

  /// Libellé du bouton pendant le blocage : « Réessayer dans 2:05 ».
  String get label => 'Réessayer dans ${formatCountdown(Duration(seconds: _seconds))}';

  /// Bloque pendant `wait` (au moins 1 s, au plus 24 h).
  void lockFor(Duration? wait) {
    _timer?.cancel();
    _seconds = (wait ?? defaultWait).inSeconds.clamp(1, 24 * 3600);
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds--;
      if (_seconds <= 0) timer.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
