import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_manager.dart';
import 'session_providers.dart';

/// Une session vient d'EXPIRER pendant l'utilisation (et non d'être fermée par l'utilisateur) :
/// la feuille « session expirée » doit être vue avant de revenir à la connexion.
///
/// `true` : la feuille est due. Tant qu'elle l'est, la garde de navigation laisse l'écran en place
/// (masqué par la feuille, fond opaque) ; « Se reconnecter » appelle [acknowledge].
class SessionExpiryNotice extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(sessionStateProvider, (previous, next) {
      if (previous is SessionActive && next == const SessionEnded(SessionEndReason.expired)) {
        state = true;
      }
    });
    return false;
  }

  void acknowledge() => state = false;
}

final sessionExpiryNoticeProvider = NotifierProvider<SessionExpiryNotice, bool>(
  SessionExpiryNotice.new,
);
