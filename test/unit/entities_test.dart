import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/app_user.dart';
import 'package:dailo/domain/entities/dates.dart';
import 'package:dailo/domain/entities/feedback_note.dart';
import 'package:dailo/domain/entities/network.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for Firestore's Timestamp, which has a `toDate()` method.
/// The domain layer must read it without importing Firestore.
class _FakeTimestamp {
  const _FakeTimestamp(this.date);

  final DateTime date;

  DateTime toDate() => date;
}

final _created = DateTime(2026, 11, 10, 9, 0);
final _updated = DateTime(2026, 11, 12, 15, 30);
final _paid = DateTime(2026, 11, 11, 18, 45);

AppUser _user() => AppUser(
  uid: 'u1',
  firstName: 'Aline',
  lastName: 'Mukamana',
  email: 'aline@example.com',
  phone: '0788000001',
  network: Network.mtn,
  createdAt: _created,
  updatedAt: _updated,
);

Recipient _recipient({DateTime? lastPaidAt, Network network = Network.mtn}) {
  return Recipient(
    id: 'r1',
    name: 'Uwase Diane',
    phone: '0788452310',
    network: network,
    isFavorite: true,
    lastPaidAt: lastPaidAt,
    createdAt: _created,
    updatedAt: _updated,
  );
}

TransactionRecord _transaction({
  String? recipientId,
  TxType type = TxType.send,
  TxStatus status = TxStatus.success,
  Network network = Network.mtn,
}) {
  return TransactionRecord(
    id: 't1',
    type: type,
    recipientId: recipientId,
    counterpartyName: 'Uwase Diane',
    counterpartyPhone: '0788452310',
    network: network,
    amount: 10000,
    fee: 100,
    comment: 'Tomatoes, Tuesday',
    status: status,
    createdAt: _created,
    updatedAt: _updated,
  );
}

void main() {
  group('toMap then fromMap gives back the same object', () {
    test('AppUser', () {
      final user = _user();
      expect(AppUser.fromMap('u1', user.toMap()), user);
    });

    test('Recipient with lastPaidAt', () {
      final recipient = _recipient(lastPaidAt: _paid);
      expect(Recipient.fromMap('r1', recipient.toMap()), recipient);
    });

    test('Recipient without lastPaidAt', () {
      final recipient = _recipient();
      expect(Recipient.fromMap('r1', recipient.toMap()), recipient);
    });

    test('Recipient on Airtel', () {
      final recipient = _recipient(network: Network.airtel);
      expect(Recipient.fromMap('r1', recipient.toMap()), recipient);
    });

    test('TransactionRecord with recipientId', () {
      final tx = _transaction(recipientId: 'r1');
      expect(TransactionRecord.fromMap('t1', tx.toMap()), tx);
    });

    test('TransactionRecord without recipientId', () {
      final tx = _transaction();
      expect(TransactionRecord.fromMap('t1', tx.toMap()), tx);
    });

    test('TransactionRecord of every type and status', () {
      for (final type in TxType.values) {
        for (final status in TxStatus.values) {
          final tx = _transaction(type: type, status: status);
          expect(TransactionRecord.fromMap('t1', tx.toMap()), tx);
        }
      }
    });
  });

  group('the id comes from the document, not the map', () {
    test('toMap has no id key', () {
      expect(_user().toMap().containsKey('uid'), isFalse);
      expect(_user().toMap().containsKey('id'), isFalse);
      expect(_recipient().toMap().containsKey('id'), isFalse);
      expect(_transaction().toMap().containsKey('id'), isFalse);
    });

    test('fromMap uses the id it is given', () {
      expect(AppUser.fromMap('u9', _user().toMap()).uid, 'u9');
      expect(Recipient.fromMap('r9', _recipient().toMap()).id, 'r9');
      expect(TransactionRecord.fromMap('t9', _transaction().toMap()).id, 't9');
    });
  });

  group('map keys match the ERD field list exactly', () {
    // Firestore rules check the exact set of fields, so a missing or extra
    // key would make every write fail.
    test('AppUser', () {
      expect(_user().toMap().keys.toList(), AppUser.fields);
    });

    test('Recipient with lastPaidAt', () {
      expect(
        _recipient(lastPaidAt: _paid).toMap().keys.toList(),
        Recipient.fields,
      );
    });

    // An unset optional field is still written, as null.
    test('Recipient without lastPaidAt', () {
      final map = _recipient().toMap();
      expect(map.keys.toList(), Recipient.fields);
      expect(map['lastPaidAt'], isNull);
    });

    test('TransactionRecord with recipientId', () {
      expect(
        _transaction(recipientId: 'r1').toMap().keys.toList(),
        TransactionRecord.fields,
      );
    });

    test('TransactionRecord without recipientId', () {
      final map = _transaction().toMap();
      expect(map.keys.toList(), TransactionRecord.fields);
      expect(map['recipientId'], isNull);
    });

    test('FeedbackNote', () {
      final note = FeedbackNote(
        message: 'Please add dark mode to the amount screen.',
        rating: 4,
        createdAt: _created,
      );
      expect(note.toMap().keys.toList(), FeedbackNote.fields);
    });

    test('TransactionRecord does not store total', () {
      expect(_transaction().toMap().containsKey('total'), isFalse);
    });
  });

  group('stored values', () {
    test('FeedbackNote keeps its message, rating and date', () {
      final note = FeedbackNote(
        message: 'Please add dark mode to the amount screen.',
        rating: 4,
        createdAt: _created,
      );
      final map = note.toMap();
      expect(map['message'], 'Please add dark mode to the amount screen.');
      expect(map['rating'], 4);
      expect(map['createdAt'], _created);
    });

    test('networks are stored as mtn and airtel', () {
      expect(_user().toMap()['network'], 'mtn');
      expect(_recipient().toMap()['network'], 'mtn');
      expect(_recipient(network: Network.airtel).toMap()['network'], 'airtel');
      expect(
        _transaction(network: Network.airtel).toMap()['network'],
        'airtel',
      );
    });

    test('transaction types are stored as send, airtime and data', () {
      expect(_transaction(type: TxType.send).toMap()['type'], 'send');
      expect(_transaction(type: TxType.airtime).toMap()['type'], 'airtime');
      expect(_transaction(type: TxType.data).toMap()['type'], 'data');
    });

    test('statuses are stored as pending, success and failed', () {
      expect(
        _transaction(status: TxStatus.pending).toMap()['status'],
        'pending',
      );
      expect(
        _transaction(status: TxStatus.success).toMap()['status'],
        'success',
      );
      expect(_transaction(status: TxStatus.failed).toMap()['status'], 'failed');
    });

    test('plain fields are stored as they are', () {
      final map = _transaction(recipientId: 'r1').toMap();
      expect(map['recipientId'], 'r1');
      expect(map['counterpartyName'], 'Uwase Diane');
      expect(map['counterpartyPhone'], '0788452310');
      expect(map['amount'], 10000);
      expect(map['fee'], 100);
      expect(map['comment'], 'Tomatoes, Tuesday');
    });

    test('dates are stored as DateTime values', () {
      final user = _user().toMap();
      expect(user['createdAt'], isA<DateTime>());
      expect(user['createdAt'], _created);
      expect(user['updatedAt'], _updated);

      final recipient = _recipient(lastPaidAt: _paid).toMap();
      expect(recipient['lastPaidAt'], isA<DateTime>());
      expect(recipient['lastPaidAt'], _paid);
      expect(recipient['createdAt'], _created);

      final tx = _transaction().toMap();
      expect(tx['createdAt'], isA<DateTime>());
      expect(tx['updatedAt'], _updated);
    });
  });

  group('fromMap is forgiving about old or damaged documents', () {
    test('a missing comment becomes an empty string', () {
      final map = Map.of(_transaction().toMap())..remove('comment');
      expect(TransactionRecord.fromMap('t1', map).comment, '');
    });

    test('a missing isFavorite becomes false', () {
      final map = Map.of(_recipient().toMap())..remove('isFavorite');
      expect(Recipient.fromMap('r1', map).isFavorite, isFalse);
    });

    test('a missing lastPaidAt becomes null', () {
      final map = Map.of(_recipient(lastPaidAt: _paid).toMap())
        ..remove('lastPaidAt');
      expect(Recipient.fromMap('r1', map).lastPaidAt, isNull);
    });

    test('a missing recipientId becomes null', () {
      final map = Map.of(_transaction(recipientId: 'r1').toMap())
        ..remove('recipientId');
      expect(TransactionRecord.fromMap('t1', map).recipientId, isNull);
    });

    test('an unknown network falls back to MTN', () {
      final userMap = Map.of(_user().toMap())..['network'] = 'orange';
      final recipientMap = Map.of(_recipient(network: Network.airtel).toMap())
        ..['network'] = 'orange';
      final txMap = Map.of(_transaction(network: Network.airtel).toMap())
        ..['network'] = 'orange';
      expect(AppUser.fromMap('u1', userMap).network, Network.mtn);
      expect(Recipient.fromMap('r1', recipientMap).network, Network.mtn);
      expect(TransactionRecord.fromMap('t1', txMap).network, Network.mtn);
    });

    test('an unknown type falls back to send', () {
      final map = Map.of(_transaction(type: TxType.data).toMap())
        ..['type'] = 'gift';
      expect(TransactionRecord.fromMap('t1', map).type, TxType.send);
    });

    test('an unknown status falls back to pending', () {
      final map = Map.of(_transaction().toMap())..['status'] = 'refunded';
      expect(TransactionRecord.fromMap('t1', map).status, TxStatus.pending);
    });
  });

  group('fromMap reads Firestore-style timestamps', () {
    test('AppUser', () {
      final map = Map.of(_user().toMap())
        ..['createdAt'] = _FakeTimestamp(_created)
        ..['updatedAt'] = _FakeTimestamp(_updated);
      expect(AppUser.fromMap('u1', map), _user());
    });

    test('Recipient, including lastPaidAt', () {
      final map = Map.of(_recipient(lastPaidAt: _paid).toMap())
        ..['lastPaidAt'] = _FakeTimestamp(_paid)
        ..['createdAt'] = _FakeTimestamp(_created)
        ..['updatedAt'] = _FakeTimestamp(_updated);
      expect(Recipient.fromMap('r1', map), _recipient(lastPaidAt: _paid));
    });

    test('TransactionRecord', () {
      final map = Map.of(_transaction().toMap())
        ..['createdAt'] = _FakeTimestamp(_created)
        ..['updatedAt'] = _FakeTimestamp(_updated);
      expect(TransactionRecord.fromMap('t1', map), _transaction());
    });
  });

  group('readDate and readDateOrNull', () {
    final fallback = DateTime(2000, 1, 1);

    test('a DateTime is returned as it is', () {
      expect(readDate(_created, fallback: fallback), _created);
    });

    test('an int is read as milliseconds since epoch', () {
      final millis = _created.millisecondsSinceEpoch;
      expect(readDate(millis, fallback: fallback), _created);
    });

    test('any object with toDate() is read through that method', () {
      expect(readDate(_FakeTimestamp(_created), fallback: fallback), _created);
    });

    test('anything else gives the fallback', () {
      expect(readDate('not a date', fallback: fallback), fallback);
      expect(readDate(true, fallback: fallback), fallback);
      expect(readDate(null, fallback: fallback), fallback);
    });

    test('readDateOrNull keeps a missing value as null', () {
      expect(readDateOrNull(null), isNull);
    });

    test('readDateOrNull reads the same three kinds as readDate', () {
      expect(readDateOrNull(_created), _created);
      expect(readDateOrNull(_created.millisecondsSinceEpoch), _created);
      expect(readDateOrNull(_FakeTimestamp(_created)), _created);
    });

    test('readDateOrNull gives null for something that is not a date', () {
      expect(readDateOrNull('not a date'), isNull);
    });
  });

  group('enum fromWire', () {
    test('Network round-trips every value', () {
      for (final network in Network.values) {
        expect(Network.fromWire(network.wire), network);
      }
    });

    test('Network falls back to MTN', () {
      expect(Network.fromWire('orange'), Network.mtn);
      expect(Network.fromWire(null), Network.mtn);
      expect(Network.fromWire(42), Network.mtn);
    });

    test('TxType round-trips every value', () {
      for (final type in TxType.values) {
        expect(TxType.fromWire(type.wire), type);
      }
    });

    test('TxType falls back to send', () {
      expect(TxType.fromWire('gift'), TxType.send);
      expect(TxType.fromWire(null), TxType.send);
    });

    test('TxStatus round-trips every value', () {
      for (final status in TxStatus.values) {
        expect(TxStatus.fromWire(status.wire), status);
      }
    });

    test('TxStatus falls back to pending', () {
      expect(TxStatus.fromWire('refunded'), TxStatus.pending);
      expect(TxStatus.fromWire(null), TxStatus.pending);
    });

    test('AppLanguage round-trips every value', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromCode(language.code), language);
      }
    });

    test('AppLanguage falls back to English', () {
      expect(AppLanguage.fromCode('fr'), AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
    });
  });

  group('small computed values', () {
    test('Recipient.displayName is the name', () {
      expect(_recipient().displayName, 'Uwase Diane');
    });

    test('Recipient.displayName is the phone when the name is empty', () {
      final unnamed = _recipient().copyWith(name: '');
      expect(unnamed.displayName, '0788452310');
    });

    test('TransactionRecord.total is amount plus fee', () {
      expect(_transaction().total, 10100);
    });

    test('AppUser.fullName joins first and last name', () {
      expect(_user().fullName, 'Aline Mukamana');
    });

    test('AppUser.fullName has no stray space without a last name', () {
      final user = _user().copyWith(lastName: '');
      expect(user.fullName, 'Aline');
    });
  });

  group('AppSettings', () {
    test('starts with light theme, MTN, fee warning on, English', () {
      const settings = AppSettings();
      expect(settings.darkMode, isFalse);
      expect(settings.defaultNetwork, Network.mtn);
      expect(settings.feeWarning, isTrue);
      expect(settings.language, AppLanguage.english);
    });

    test('copyWith changes darkMode only', () {
      final changed = const AppSettings().copyWith(darkMode: true);
      expect(
        changed,
        const AppSettings(
          darkMode: true,
          defaultNetwork: Network.mtn,
          feeWarning: true,
          language: AppLanguage.english,
        ),
      );
    });

    test('copyWith changes defaultNetwork only', () {
      final changed = const AppSettings().copyWith(
        defaultNetwork: Network.airtel,
      );
      expect(
        changed,
        const AppSettings(
          darkMode: false,
          defaultNetwork: Network.airtel,
          feeWarning: true,
          language: AppLanguage.english,
        ),
      );
    });

    test('copyWith changes feeWarning only', () {
      final changed = const AppSettings().copyWith(feeWarning: false);
      expect(
        changed,
        const AppSettings(
          darkMode: false,
          defaultNetwork: Network.mtn,
          feeWarning: false,
          language: AppLanguage.english,
        ),
      );
    });

    test('copyWith changes language only', () {
      final changed = const AppSettings().copyWith(
        language: AppLanguage.kinyarwanda,
      );
      expect(
        changed,
        const AppSettings(
          darkMode: false,
          defaultNetwork: Network.mtn,
          feeWarning: true,
          language: AppLanguage.kinyarwanda,
        ),
      );
    });

    test('copyWith with nothing returns an equal settings object', () {
      const settings = AppSettings(darkMode: true, feeWarning: false);
      expect(settings.copyWith(), settings);
    });
  });
}
