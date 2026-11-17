import 'package:dailo/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatNumber', () {
    test('puts a comma between thousands', () {
      expect(formatNumber(10500), '10,500');
      expect(formatNumber(1000000), '1,000,000');
    });

    test('leaves small numbers alone', () {
      expect(formatNumber(0), '0');
      expect(formatNumber(999), '999');
    });
  });

  group('formatFrw', () {
    test('adds the currency after the number', () {
      expect(formatFrw(10500), '10,500 Frw');
    });
  });

  group('formatDateTime and formatDate', () {
    test('writes day, short month, year, then 24-hour time', () {
      expect(
        formatDateTime(DateTime(2026, 9, 27, 14, 32)),
        '27 Sep 2026, 14:32',
      );
    });

    test('pads the hour and minute but not the day', () {
      expect(formatDateTime(DateTime(2026, 1, 5, 9, 5)), '5 Jan 2026, 09:05');
    });

    test('midnight shows as 00:00', () {
      expect(formatDateTime(DateTime(2026, 9, 27, 0, 0)), '27 Sep 2026, 00:00');
    });

    test('formatDate leaves out the time', () {
      expect(formatDate(DateTime(2026, 9, 27, 14, 32)), '27 Sep 2026');
    });

    test('every month has its own three-letter name', () {
      const names = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      for (var month = 1; month <= 12; month++) {
        expect(
          formatDate(DateTime(2026, month, 1)),
          '1 ${names[month - 1]} 2026',
        );
      }
    });
  });

  group('dayBucket', () {
    final now = DateTime(2026, 9, 27, 14, 32);

    test('the same calendar day is today', () {
      expect(dayBucket(DateTime(2026, 9, 27, 0, 0), now: now), DayBucket.today);
      expect(
        dayBucket(DateTime(2026, 9, 27, 14, 0), now: now),
        DayBucket.today,
      );
    });

    // Calendar days, not 24-hour periods: two minutes apart can still be
    // different days.
    test('23:59 the day before is yesterday when it is just past midnight', () {
      final justPastMidnight = DateTime(2026, 9, 27, 0, 1);
      expect(
        dayBucket(DateTime(2026, 9, 26, 23, 59), now: justPastMidnight),
        DayBucket.yesterday,
      );
    });

    test('38 hours ago is still yesterday if it was on the day before', () {
      // 26 Sep 00:01 to 27 Sep 14:32 is more than a day, but one calendar day.
      expect(
        dayBucket(DateTime(2026, 9, 26, 0, 1), now: now),
        DayBucket.yesterday,
      );
    });

    test('yesterday works across a month and a year', () {
      expect(
        dayBucket(
          DateTime(2026, 9, 30, 20, 0),
          now: DateTime(2026, 10, 1, 9, 0),
        ),
        DayBucket.yesterday,
      );
      expect(
        dayBucket(
          DateTime(2025, 12, 31, 20, 0),
          now: DateTime(2026, 1, 1, 9, 0),
        ),
        DayBucket.yesterday,
      );
    });

    test('two days back is earlier', () {
      expect(
        dayBucket(DateTime(2026, 9, 25, 14, 32), now: now),
        DayBucket.earlier,
      );
    });

    test('25 hours ago can be earlier when it was two calendar days ago', () {
      expect(
        dayBucket(
          DateTime(2026, 9, 25, 23, 30),
          now: DateTime(2026, 9, 27, 0, 30),
        ),
        DayBucket.earlier,
      );
    });

    test('a month ago is earlier', () {
      expect(dayBucket(DateTime(2026, 8, 27), now: now), DayBucket.earlier);
    });
  });

  group('initialsOf', () {
    test('two words give two capitals', () {
      expect(initialsOf('Uwase Diane'), 'UD');
    });

    test('one lower-case word gives one capital', () {
      expect(initialsOf('aline'), 'A');
    });

    test('three words use the first two', () {
      expect(initialsOf('Jean Bosco Habimana'), 'JB');
    });

    test('a phone number gives #', () {
      expect(initialsOf('0788452310'), '#');
    });

    test('an empty name gives #', () {
      expect(initialsOf(''), '#');
    });
  });
}
