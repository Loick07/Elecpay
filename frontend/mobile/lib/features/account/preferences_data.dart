import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached_api.dart';
import '../../core/models/account.dart';
import '../../core/session/session_providers.dart';

// « Me prévenir » de l'écran 14 : `GET` / `PATCH /me/notification-preferences`. Les interrupteurs
// sont appliqués par le serveur à chaque notification (`insert_notifications`, B9).

/// Un interrupteur de « Me prévenir » : clé de l'API, libellé et sous-titre (textes du contrat et
/// de la maquette).
enum PreferenceSwitch {
  dueSoon('due_soon', 'Échéances', '5 jours avant, puis le jour même'),
  payments('payments', 'Paiements', 'Réussis, échoués, reçus disponibles'),
  highConsumption(
    'high_consumption',
    'Consommation inhabituelle',
    'Quand un jour dépasse votre moyenne de 30 %',
  ),
  emailReceipts('email_receipts', 'Reçus par e-mail', 'Le reçu PDF, à votre adresse vérifiée');

  const PreferenceSwitch(this.apiKey, this.label, this.detail);

  final String apiKey;
  final String label;
  final String detail;

  bool valueIn(NotificationPreferences p) => switch (this) {
    dueSoon => p.dueSoon,
    payments => p.payments,
    highConsumption => p.highConsumption,
    emailReceipts => p.emailReceipts,
  };

  NotificationPreferences withValue(NotificationPreferences p, bool value) => switch (this) {
    dueSoon => p.copyWith(dueSoon: value),
    payments => p.copyWith(payments: value),
    highConsumption => p.copyWith(highConsumption: value),
    emailReceipts => p.copyWith(emailReceipts: value),
  };
}

/// Préférences lues par le cache hors ligne ; un interrupteur change tout de suite à l'écran, et
/// revient en arrière si l'API refuse (l'écran affiche le message).
class PreferencesNotifier extends AsyncNotifier<Fetched<NotificationPreferences>> {
  @override
  Future<Fetched<NotificationPreferences>> build() => ref
      .watch(cachedApiProvider)
      .get('/me/notification-preferences', NotificationPreferences.fromJson);

  /// Change un interrupteur. Jamais hors ligne (préférences du cache : rien n'est envoyé).
  Future<void> set(PreferenceSwitch which, bool value) async {
    final current = state.value;
    if (current == null || current is CachedData<NotificationPreferences>) return;
    state = AsyncData(FreshData(which.withValue(current.data, value)));
    try {
      final saved = await ref
          .read(authenticatedApiProvider)
          .patchObject(
            '/me/notification-preferences',
            NotificationPreferences.fromJson,
            body: {which.apiKey: value},
          );
      state = AsyncData(FreshData(saved));
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, Fetched<NotificationPreferences>>(
      PreferencesNotifier.new,
    );
