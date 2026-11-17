/// Dates, heures et périodes au format de la charte et des maquettes, en français.
///
/// Deux sortes de dates arrivent de l'API :
/// - un INSTANT (`date-time`, ex. `issued_at`) : affiché à l'heure de Brazzaville (UTC+1, sans heure
///   d'été), comme le backend (`backend/app/core/timezone.py`) ;
/// - une DATE DU CALENDRIER (`date`, ex. `due_date`, `period_start`) : affichée telle quelle,
///   sans conversion (le 18 novembre reste le 18 novembre).
library;

import 'typography.dart';

/// Décalage de Brazzaville par rapport à UTC.
const brazzavilleOffset = Duration(hours: 1);

const _monthsShort = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

const _monthsLong = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// L'instant `moment` vu à Brazzaville (les champs jour / heure sont ceux de Brazzaville).
DateTime toBrazzaville(DateTime moment) => moment.toUtc().add(brazzavilleOffset);

String _two(int n) => n.toString().padLeft(2, '0');

/// « 1er » le premier du mois, sinon le nombre.
String _day(int day) => day == 1 ? '1er' : '$day';

String _short(int month) => _monthsShort[month - 1];

/// Date du calendrier (`date` de l'API) : « 18 nov. 2026 », « 1er sept. 2026 ».
String formatCalendarDate(DateTime date) => '${_day(date.day)} ${_short(date.month)} ${date.year}';

/// Instant (`date-time` de l'API), jour seulement, heure de Brazzaville : « 25 nov. 2026 ».
String formatDate(DateTime moment) => formatCalendarDate(toBrazzaville(moment));

/// Instant avec l'heure, à Brazzaville : « 12 nov. à 08:15 » ; l'année est ajoutée si elle n'est pas
/// celle de `now` (« 12 nov. 2025 à 08:15 »).
String formatDateTime(DateTime moment, {required DateTime now}) {
  final local = toBrazzaville(moment);
  final sameYear = local.year == toBrazzaville(now).year;
  final day = '${_day(local.day)} ${_short(local.month)}${sameYear ? '' : ' ${local.year}'}';
  return '$day à ${_two(local.hour)}:${_two(local.minute)}';
}

/// Mois de consommation : « Octobre 2026 ».
String formatMonthYear(int year, int month) {
  final name = _monthsLong[month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} $year';
}

int _monthIndex(DateTime d) => d.year * 12 + d.month;

/// Période d'une facture (dates du calendrier, fin incluse), comme la maquette de l'écran 7 :
/// « 1er sept. – 31 oct. 2026 · 2 mois » ; sur deux années : « 1er déc. 2026 – 31 janv. 2027 · 2 mois ».
String formatBillPeriod(DateTime start, DateTime end) {
  final months = _monthIndex(end) - _monthIndex(start) + 1;
  final from = start.year == end.year
      ? '${_day(start.day)} ${_short(start.month)}'
      : formatCalendarDate(start);
  return '$from $enDash ${formatCalendarDate(end)} · $months mois';
}

/// Période courte (listes) : « sept.–oct. 2026 » ; « déc. 2026–janv. 2027 » ; un seul mois : « oct. 2026 ».
String formatBillPeriodShort(DateTime start, DateTime end) {
  if (_monthIndex(start) == _monthIndex(end)) return '${_short(end.month)} ${end.year}';
  if (start.year == end.year) {
    return '${_short(start.month)}$enDash${_short(end.month)} ${end.year}';
  }
  return '${_short(start.month)} ${start.year}$enDash${_short(end.month)} ${end.year}';
}

/// Bannière d'un écran montré depuis le cache (texte de la charte) :
/// « Hors connexion. Les données affichées datent du 12 nov. à 08:15. »
String offlineLabel(DateTime savedAt, {required DateTime now}) =>
    'Hors connexion. Les données affichées datent du ${formatDateTime(savedAt, now: now)}.';
