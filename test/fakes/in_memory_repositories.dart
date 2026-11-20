import 'dart:async';

import 'package:dailo/domain/entities/app_settings.dart';
import 'package:dailo/domain/entities/app_user.dart';
import 'package:dailo/domain/entities/feedback_note.dart';
import 'package:dailo/domain/entities/recipient.dart';
import 'package:dailo/domain/entities/transaction_record.dart';
import 'package:dailo/domain/repositories/feedback_repository.dart';
import 'package:dailo/domain/repositories/profile_repository.dart';
import 'package:dailo/domain/repositories/recipient_repository.dart';
import 'package:dailo/domain/repositories/settings_repository.dart';
import 'package:dailo/domain/repositories/transaction_repository.dart';
import 'package:dailo/domain/services/ussd_launcher.dart';

/// Shared behaviour for the in-memory repositories: set [failNext] to make
/// the next write throw, the way a rejected Firestore write would.
mixin FailsOnDemand {
  bool failNext = false;

  void maybeFail() {
    if (failNext) {
      failNext = false;
      throw Exception('write rejected');
    }
  }

  final _writeFailures = StreamController<void>.broadcast();

  /// What the real repositories expose: one event per write the server
  /// refused after the app had already shown it.
  Stream<void> get writeFailures => _writeFailures.stream;

  /// Call from a test to act out the server refusing an earlier write.
  void rejectLastWrite() => _writeFailures.add(null);
}

/// Recipients kept in a list per user. Every change is pushed to listeners,
/// like a Firestore snapshot stream.
class InMemoryRecipientRepository
    with FailsOnDemand
    implements RecipientRepository {
  InMemoryRecipientRepository([List<Recipient> seed = const []])
    : items = [...seed];

  /// The stored recipients for the test user.
  final List<Recipient> items;
  final _controller = StreamController<List<Recipient>>.broadcast();
  int _nextId = 1;

  void _push() => _controller.add(List.unmodifiable(items));

  @override
  Stream<List<Recipient>> watchAll(String uid) async* {
    yield List.unmodifiable(items);
    yield* _controller.stream;
  }

  @override
  Future<String> add(String uid, Recipient recipient) async {
    maybeFail();
    final id = 'new${_nextId++}';
    items.add(recipient.copyWith(id: id));
    _push();
    return id;
  }

  @override
  Future<void> update(String uid, Recipient recipient) async {
    maybeFail();
    final index = items.indexWhere((item) => item.id == recipient.id);
    if (index >= 0) items[index] = recipient;
    _push();
  }

  @override
  Future<void> delete(String uid, String recipientId) async {
    maybeFail();
    items.removeWhere((item) => item.id == recipientId);
    _push();
  }
}

/// Transactions kept newest first.
class InMemoryTransactionRepository
    with FailsOnDemand
    implements TransactionRepository {
  InMemoryTransactionRepository([List<TransactionRecord> seed = const []])
    : items = [...seed];

  final List<TransactionRecord> items;
  final _controller = StreamController<List<TransactionRecord>>.broadcast();
  int _nextId = 1;

  void _push() {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(List.unmodifiable(items));
  }

  @override
  Stream<List<TransactionRecord>> watchAll(String uid) async* {
    yield List.unmodifiable(items);
    yield* _controller.stream;
  }

  @override
  Future<String> add(String uid, TransactionRecord record) async {
    maybeFail();
    final id = 'tx${_nextId++}';
    items.add(record.copyWith(id: id));
    _push();
    return id;
  }

  @override
  Future<void> setStatus(String uid, String recordId, TxStatus status) async {
    maybeFail();
    final index = items.indexWhere((item) => item.id == recordId);
    if (index >= 0) items[index] = items[index].copyWith(status: status);
    _push();
  }

  @override
  Future<void> delete(String uid, String recordId) async {
    maybeFail();
    items.removeWhere((item) => item.id == recordId);
    _push();
  }
}

class FakeProfileRepository with FailsOnDemand implements ProfileRepository {
  FakeProfileRepository([this.user]);

  AppUser? user;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> watch(String uid) async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  Future<void> update(AppUser value) async {
    maybeFail();
    user = value;
    _controller.add(value);
  }
}

class FakeFeedbackRepository with FailsOnDemand implements FeedbackRepository {
  final List<FeedbackNote> sent = [];

  @override
  Future<void> send(String uid, FeedbackNote note) async {
    maybeFail();
    sent.add(note);
  }
}

/// Settings kept in memory. [saves] counts how many times they were saved.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this.stored = const AppSettings()]);

  AppSettings stored;
  int saves = 0;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
    saves++;
  }
}

/// A dialer that never touches the phone. Set [outcome] to choose what it
/// reports; [codes] records every code it was asked to dial.
class FakeUssdLauncher implements UssdLauncher {
  UssdOutcome outcome = UssdOutcome.launched;
  final List<String> codes = [];

  @override
  Future<UssdOutcome> run(String code) async {
    codes.add(code);
    return outcome;
  }
}