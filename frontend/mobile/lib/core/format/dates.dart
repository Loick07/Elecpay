/// Dates et heures affichées : toujours à l'heure de Brazzaville (UTC+1, sans heure d'été), comme le
/// backend (`backend/app/core/timezone.py`). Ce module grandira en F2 (FCFA, kWh, +242, périodes).
library;

/// Décalage de Brazzaville par rapport à UTC.
const brazzavilleOffset = Duration(hours: 1);

/// L'instant `moment` vu à Brazzaville (les champs jour / heure sont ceux de Brazzaville).
DateTime toBrazzaville(DateTime moment) => moment.toUtc().add(brazzavilleOffset);

String _two(int n) => n.toString().padLeft(2, '0');

/// « 16/11/2026 à 13:20 » (heure de Brazzaville).
String formatDateTime(DateTime moment) {
  final local = toBrazzaville(moment);
  return '${_two(local.day)}/${_two(local.month)}/${local.year} à '
      '${_two(local.hour)}:${_two(local.minute)}';
}

/// Mention affichée sur un écran montré depuis le cache : « Hors ligne · données du 16/11/2026 à 13:20 ».
String offlineLabel(DateTime savedAt) => 'Hors ligne · données du ${formatDateTime(savedAt)}';
