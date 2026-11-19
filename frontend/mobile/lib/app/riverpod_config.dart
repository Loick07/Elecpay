/// Relance automatique des lectures en échec : JAMAIS.
///
/// Par défaut, Riverpod 3 relance un fournisseur en échec jusqu'à 10 fois (de 200 ms à 6,4 s
/// d'attente) et le laisse « en chargement » pendant ce temps : hors ligne, une carte montrerait un
/// squelette près d'une minute au lieu de l'état « hors connexion », et enverrait 10 requêtes.
/// Règle d'ElecPay (F1) : aucune relance automatique ; c'est l'utilisateur qui touche « Réessayer »
/// ou tire l'écran pour actualiser. Vu en F4.1 (19/11/2026).
///
/// À passer à TOUT conteneur Riverpod : `ProviderScope(retry: noAutomaticRetry)` (lib/main.dart),
/// `ProviderContainer(retry: noAutomaticRetry)` (tests).
Duration? noAutomaticRetry(int retryCount, Object error) => null;
