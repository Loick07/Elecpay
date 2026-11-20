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

/// Date du calendrier sans l'année (listes de l'année en cours) : « 18 nov. », « 1er sept. ».
String formatDayMonth(DateTime date) => '${_day(date.day)} ${_short(date.month)}';

/// Urgence d'une échéance (couleur du compte à rebours, maquette de la carte héros) :
/// plus de 5 jours → normale ; 5 jours ou moins → proche (`warning`) ; dépassée → en retard (`error`).
enum DueUrgency { normal, soon, overdue }

/// Compte à rebours jusqu'à `dueDate` (date du calendrier), vu le jour de `now` à Brazzaville :
/// « dans 6 jours », « demain », « aujourd'hui », « en retard de 3 jours ».
({String text, DueUrgency urgency}) dueCountdown(DateTime dueDate, {required DateTime now}) {
  final local = toBrazzaville(now);
  final today = DateTime.utc(local.year, local.month, local.day);
  final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
  final days = due.difference(today).inDays;
  if (days < 0) {
    final late = -days;
    return (text: 'en retard de $late jour${late > 1 ? 's' : ''}', urgency: DueUrgency.overdue);
  }
  final urgency = days <= 5 ? DueUrgency.soon : DueUrgency.normal;
  final text = switch (days) {
    0 => 'aujourd’hui',
    1 => 'demain',
    _ => 'dans $days jours',
  };
  return (text: text, urgency: urgency);
}

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

/// Heure seule, à Brazzaville : « 14:31 » (étapes d'un paiement).
String formatTime(DateTime moment) {
  final local = toBrazzaville(moment);
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// Compte à rebours en minutes:secondes (« 2:45 », « 0:42 ») ; arrondi à la seconde supérieure.
String formatCountdown(Duration remaining) {
  final seconds = remaining.isNegative ? 0 : (remaining.inMilliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${_two(seconds % 60)}';
}

const _weekdays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

String _capitalized(String word) => '${word[0].toUpperCase()}${word.substring(1)}';

/// Jour de l'en-tête de l'accueil, à Brazzaville : « Jeudi 12 novembre », « Dimanche 1er mars ».
String formatWeekdayDate(DateTime moment) {
  final local = toBrazzaville(moment);
  return '${_capitalized(_weekdays[local.weekday - 1])} ${_day(local.day)} '
      '${_monthsLong[local.month - 1]}';
}

const _weekdaysShort = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];

/// Nom du jour d'une date du calendrier, avec sa majuscule : « Lundi ».
String formatWeekdayName(DateTime day) => _capitalized(_weekdays[day.weekday - 1]);

/// Moment d'une notification (maquette de l'écran 13), à Brazzaville, selon son groupe (`group` de
/// l'API) : aujourd'hui « 14:32 » ; cette semaine « Dim. » ; plus tôt « 3 nov. » (« 3 nov. 2025 »
/// si ce n'est pas l'année de `now`).
String formatNotificationTime(DateTime moment, String group, {required DateTime now}) {
  final local = toBrazzaville(moment);
  return switch (group) {
    'today' => '${_two(local.hour)}:${_two(local.minute)}',
    'this_week' => _weekdaysShort[local.weekday - 1],
    _ => local.year == toBrazzaville(now).year ? formatDayMonth(local) : formatCalendarDate(local),
  };
}

/// Titre d'une semaine (écran Consommation) : « Sem. du 12 oct. » (`monday` : date du calendrier).
String formatWeekTitle(DateTime monday) => 'Sem. du ${formatDayMonth(monday)}';

/// Titre d'un jour (écran Consommation) : « Mer. 14 oct. » (date du calendrier).
String formatDayTitle(DateTime day) => '${_weekdaysShort[day.weekday - 1]} ${formatDayMonth(day)}';

/// Jour court du fil d'Ariane : « Mer. 14 ».
String formatDayCrumb(DateTime day) => '${_weekdaysShort[day.weekday - 1]} ${_day(day.day)}';

/// Nom du mois seul, avec sa majuscule : « Octobre ».
String formatMonthName(int month) => _capitalized(_monthsLong[month - 1]);

/// Initiale du mois pour les barres de l'année : « J », « F », « M »…
String formatMonthInitial(int month) => _monthsLong[month - 1][0].toUpperCase();

/// Date d'API (« 2026-10-14 ») d'une date du calendrier.
String formatApiDate(DateTime day) => '${day.year}-${_two(day.month)}-${_two(day.day)}';

/// Mois en cours relevé (dates du calendrier) : « Novembre, du 1er au 12 » ; un seul jour :
/// « Novembre, le 1er » ; rien de relevé (`end` nul) : « Novembre ».
String formatMonthSoFar(DateTime start, DateTime? end) {
  final month = _capitalized(_monthsLong[start.month - 1]);
  if (end == null) return month;
  if (end.day == start.day) return '$month, le ${_day(end.day)}';
  return '$month, du ${_day(start.day)} au ${_day(end.day)}';
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

/// Titre d'un groupe de « Mes factures » (maquette de l'écran 6) : « Septembre – octobre 2026 » ;
/// sur deux années : « Décembre 2026 – janvier 2027 » ; un seul mois : « Octobre 2026 ».
String formatBillPeriodGroup(DateTime start, DateTime end) {
  if (_monthIndex(start) == _monthIndex(end)) return formatMonthYear(end.year, end.month);
  final from = _capitalized(_monthsLong[start.month - 1]);
  final to = _monthsLong[end.month - 1];
  if (start.year == end.year) return '$from $enDash $to ${end.year}';
  return '$from ${start.year} $enDash $to ${end.year}';
}

/// Période en toutes lettres, dans une phrase (maquette du reçu, écran 10) :
/// « septembre–octobre 2026 » ; sur deux années : « décembre 2026–janvier 2027 » ; un mois : « octobre 2026 ».
String formatBillPeriodLong(DateTime start, DateTime end) {
  final from = _monthsLong[start.month - 1];
  final to = _monthsLong[end.month - 1];
  if (_monthIndex(start) == _monthIndex(end)) return '$to ${end.year}';
  if (start.year == end.year) return '$from$enDash$to ${end.year}';
  return '$from ${start.year}$enDash$to ${end.year}';
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
