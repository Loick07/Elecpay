import 'package:elecpay/core/format/dates.dart';
import 'package:flutter_test/flutter_test.dart';

String visible(String s) => s;

void main() {
  final now = DateTime.utc(2026, 11, 17, 9);

  group('dates du calendrier (date de l’API, sans conversion)', () {
    test('« 18 nov. 2026 », « 1er » le premier du mois', () {
      expect(formatCalendarDate(DateTime(2026, 11, 18)), '18 nov. 2026');
      expect(formatCalendarDate(DateTime(2026, 9)), '1er sept. 2026');
    });

    test('les 12 abréviations de la charte', () {
      final months = [for (var m = 1; m <= 12; m++) formatCalendarDate(DateTime(2026, m, 15))];
      expect(months, [
        '15 janv. 2026',
        '15 févr. 2026',
        '15 mars 2026',
        '15 avr. 2026',
        '15 mai 2026',
        '15 juin 2026',
        '15 juil. 2026',
        '15 août 2026',
        '15 sept. 2026',
        '15 oct. 2026',
        '15 nov. 2026',
        '15 déc. 2026',
      ]);
    });

    test('point d’abréviation : jamais pour mai, juin, août ; toujours pour les 8 autres', () {
      String abbreviation(int month) => formatCalendarDate(DateTime(2026, month, 15)).split(' ')[1];
      const withoutPoint = {5: 'mai', 6: 'juin', 8: 'août'};
      const withPoint = {
        1: 'janv.',
        2: 'févr.',
        4: 'avr.',
        7: 'juil.',
        9: 'sept.',
        10: 'oct.',
        11: 'nov.',
        12: 'déc.',
      };
      for (final MapEntry(key: month, value: expected) in withoutPoint.entries) {
        expect(abbreviation(month), expected);
        expect(abbreviation(month), isNot(endsWith('.')), reason: expected);
      }
      for (final MapEntry(key: month, value: expected) in withPoint.entries) {
        expect(abbreviation(month), expected);
        expect(abbreviation(month), endsWith('.'), reason: expected);
      }
      // Mars : mot complet, donc sans point (le 12e mois de la liste).
      expect(abbreviation(3), 'mars');
      expect({...withoutPoint.keys, ...withPoint.keys, 3}, hasLength(12));
    });

    test('une date UTC à minuit reste le même jour (aucune conversion)', () {
      expect(formatCalendarDate(DateTime.utc(2026, 11, 18)), '18 nov. 2026');
    });
  });

  group('instants (date-time de l’API), heure de Brazzaville', () {
    test('jour seulement : « 25 nov. 2026 »', () {
      expect(formatDate(DateTime.utc(2026, 11, 25, 10)), '25 nov. 2026');
    });

    test('minuit passé à Brazzaville : le jour suivant', () {
      expect(formatDate(DateTime.utc(2026, 12, 31, 23, 5)), '1er janv. 2027');
    });

    test('avec l’heure, même année : « 12 nov. à 08:15 »', () {
      expect(formatDateTime(DateTime.utc(2026, 11, 12, 7, 15), now: now), '12 nov. à 08:15');
    });

    test('avec l’heure, autre année : l’année est écrite', () {
      expect(formatDateTime(DateTime.utc(2025, 11, 12, 7, 15), now: now), '12 nov. 2025 à 08:15');
    });

    test('une heure locale du téléphone est d’abord ramenée en UTC', () {
      final utc = DateTime.utc(2026, 3, 1, 8);
      expect(formatDateTime(utc.toLocal(), now: now), formatDateTime(utc, now: now));
    });
  });

  test('jour et mois sans l’année : « 18 nov. », « 1er sept. »', () {
    expect(formatDayMonth(DateTime(2026, 11, 18)), '18 nov.');
    expect(formatDayMonth(DateTime(2026, 9)), '1er sept.');
    expect(formatDayMonth(DateTime(2026, 5, 3)), '3 mai');
  });

  group('compte à rebours de l’échéance (carte héros)', () {
    // 12 nov. 2026 à 10:00 à Brazzaville.
    final today = DateTime.utc(2026, 11, 12, 9);
    ({String text, DueUrgency urgency}) countdown(DateTime due) => dueCountdown(due, now: today);

    test('loin : « dans 6 jours », urgence normale (maquette : échéance le 18 nov.)', () {
      expect(countdown(DateTime(2026, 11, 18)), (text: 'dans 6 jours', urgency: DueUrgency.normal));
    });

    test('à 5 jours ou moins : proche (warning)', () {
      expect(countdown(DateTime(2026, 11, 17)), (text: 'dans 5 jours', urgency: DueUrgency.soon));
      expect(countdown(DateTime(2026, 11, 13)), (text: 'demain', urgency: DueUrgency.soon));
      expect(countdown(DateTime(2026, 11, 12)).text, 'aujourd’hui');
      expect(countdown(DateTime(2026, 11, 12)).urgency, DueUrgency.soon);
    });

    test('après l’échéance : en retard (error), singulier et pluriel', () {
      expect(countdown(DateTime(2026, 11, 11)), (
        text: 'en retard de 1 jour',
        urgency: DueUrgency.overdue,
      ));
      expect(countdown(DateTime(2026, 11, 9)).text, 'en retard de 3 jours');
    });

    test('le jour se compte à Brazzaville (23:30 UTC = déjà le lendemain)', () {
      final lateEvening = DateTime.utc(2026, 11, 12, 23, 30); // 13 nov. 00:30 à Brazzaville
      expect(dueCountdown(DateTime(2026, 11, 13), now: lateEvening).text, 'aujourd’hui');
    });

    test('changement d’année', () {
      expect(
        dueCountdown(DateTime(2027, 1, 2), now: DateTime.utc(2026, 12, 30, 10)).text,
        'dans 3 jours',
      );
    });
  });

  test('compte à rebours « m:ss » (maquette : « Renvoyer le code dans 0:42 »)', () {
    expect(formatCountdown(const Duration(seconds: 42)), '0:42');
    expect(formatCountdown(const Duration(seconds: 165)), '2:45');
    expect(formatCountdown(const Duration(minutes: 15)), '15:00');
    expect(formatCountdown(const Duration(milliseconds: 1200)), '0:02');
    expect(formatCountdown(Duration.zero), '0:00');
    expect(formatCountdown(const Duration(seconds: -3)), '0:00');
  });

  test('mois de consommation : « Octobre 2026 », « Août 2026 »', () {
    expect(formatMonthYear(2026, 10), 'Octobre 2026');
    expect(formatMonthYear(2026, 8), 'Août 2026');
    expect(formatMonthYear(2027, 1), 'Janvier 2027');
  });

  group('période d’une facture bimestrielle (maquette de l’écran 7)', () {
    test('« 1er sept. \u2013 31 oct. 2026 · 2 mois »', () {
      expect(
        visible(formatBillPeriod(DateTime(2026, 9), DateTime(2026, 10, 31))),
        '1er sept. \u2013 31 oct. 2026 · 2 mois',
      );
    });

    test('sur deux années : les deux années sont écrites', () {
      expect(
        visible(formatBillPeriod(DateTime(2026, 12), DateTime(2027, 1, 31))),
        '1er déc. 2026 \u2013 31 janv. 2027 · 2 mois',
      );
    });

    test('février (28 jours)', () {
      expect(
        visible(formatBillPeriod(DateTime(2027), DateTime(2027, 2, 28))),
        '1er janv. \u2013 28 févr. 2027 · 2 mois',
      );
    });

    test('période d’un seul mois : « 1 mois »', () {
      expect(
        visible(formatBillPeriod(DateTime(2026, 10), DateTime(2026, 10, 31))),
        '1er oct. \u2013 31 oct. 2026 · 1 mois',
      );
    });

    test('version courte des listes : « sept.\u2013oct. 2026 »', () {
      expect(
        visible(formatBillPeriodShort(DateTime(2026, 9), DateTime(2026, 10, 31))),
        'sept.\u2013oct. 2026',
      );
      expect(
        visible(formatBillPeriodShort(DateTime(2026, 12), DateTime(2027, 1, 31))),
        'déc. 2026\u2013janv. 2027',
      );
      expect(
        visible(formatBillPeriodShort(DateTime(2026, 10), DateTime(2026, 10, 31))),
        'oct. 2026',
      );
    });
  });

  test('bannière hors connexion (texte de la charte)', () {
    expect(
      offlineLabel(DateTime.utc(2026, 11, 12, 7, 15), now: now),
      'Hors connexion. Les données affichées datent du 12 nov. à 08:15.',
    );
  });

  group('accueil', () {
    test('en-tête : « Jeudi 12 novembre », à l’heure de Brazzaville', () {
      expect(formatWeekdayDate(DateTime.utc(2026, 11, 12, 9)), 'Jeudi 12 novembre');
      // 23:30 UTC le 28 février = 00:30 le 1er mars à Brazzaville.
      expect(formatWeekdayDate(DateTime.utc(2026, 2, 28, 23, 30)), 'Dimanche 1er mars');
    });

    test('notifications : « 14:32 », « Dim. », « 3 nov. », « 28 oct. 2025 »', () {
      final now = DateTime.utc(2026, 11, 12, 15);
      expect(
        formatNotificationTime(DateTime.utc(2026, 11, 12, 13, 32), 'today', now: now),
        '14:32',
      );
      expect(formatNotificationTime(DateTime.utc(2026, 11, 8, 10), 'this_week', now: now), 'Dim.');
      expect(formatNotificationTime(DateTime.utc(2026, 11, 3, 8), 'earlier', now: now), '3 nov.');
      expect(
        formatNotificationTime(DateTime.utc(2025, 10, 28, 8), 'earlier', now: now),
        '28 oct. 2025',
      );
    });

    test('mois en cours : « Novembre, du 1er au 12 », un jour, rien de relevé', () {
      final start = DateTime(2026, 11);
      expect(formatMonthSoFar(start, DateTime(2026, 11, 12)), 'Novembre, du 1er au 12');
      expect(formatMonthSoFar(start, DateTime(2026, 11)), 'Novembre, le 1er');
      expect(formatMonthSoFar(start, null), 'Novembre');
    });
  });

  test('groupes de « Mes factures » : « Septembre – octobre 2026 »', () {
    expect(
      formatBillPeriodGroup(DateTime(2026, 9), DateTime(2026, 10, 31)),
      'Septembre – octobre 2026',
    );
    expect(
      formatBillPeriodGroup(DateTime(2026, 12), DateTime(2027, 1, 31)),
      'Décembre 2026 – janvier 2027',
    );
    expect(formatBillPeriodGroup(DateTime(2026, 10), DateTime(2026, 10, 31)), 'Octobre 2026');
  });
}
