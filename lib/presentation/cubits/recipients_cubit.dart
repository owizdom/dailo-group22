import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recipient.dart';
import '../../domain/logic/phone_number.dart';
import '../../domain/repositories/recipient_repository.dart';

/// A one-off result to show in a snack bar.
enum RecipientsMessage { added, updated, deleted, duplicate, failed }

class RecipientsState extends Equatable {
  const RecipientsState({
    this.all = const [],
    this.query = '',
    this.loading = false,
    this.message,
  });

  /// Every saved recipient, as last reported by the repository.
  final List<Recipient> all;

  /// The text in the search box.
  final String query;
  final bool loading;

  /// Set for one state only.
  final RecipientsMessage? message;

  /// [all] narrowed by [query], matching the name or the phone number.
  List<Recipient> get matching {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return all;
    final digits = text.replaceAll(RegExp(r'\s'), '');
    return all.where((recipient) {
      return recipient.name.toLowerCase().contains(text) ||
          recipient.phone.contains(digits);
    }).toList();
  }

  /// Most recently paid first. A recipient never paid is placed by the
  /// date it was added.
  List<Recipient> get recents {
    final list = [...matching];
    list.sort((a, b) {
      final aDate = a.lastPaidAt ?? a.createdAt;
      final bDate = b.lastPaidAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  /// Favourites only, in name order.
  List<Recipient> get favorites {
    final list = matching.where((recipient) => recipient.isFavorite).toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  RecipientsState copyWith({
    List<Recipient>? all,
    String? query,
    bool? loading,
    RecipientsMessage? message,
  }) {
    return RecipientsState(
      all: all ?? this.all,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      message: message,
    );
  }

  @override
  List<Object?> get props => [all, query, loading, message];
}

/// Create, read, update and delete for the user's saved recipients.
/// Home and Send Money both read this one state, so a change shows on
/// both at once.
class RecipientsCubit extends Cubit<RecipientsState> {
  RecipientsCubit(this.repository) : super(const RecipientsState());

  final RecipientRepository repository;
  StreamSubscription<List<Recipient>>? _subscription;
  StreamSubscription<void>? _failures;
  String? _uid;

  /// Starts following the recipients of [uid]. Pass null on sign-out to
  /// stop listening and clear the list.
  void watch(String? uid) {
    _stopListening();
    _uid = uid;
    if (uid == null) {
      emit(const RecipientsState());
      return;
    }
    emit(state.copyWith(loading: true));
    // The server can refuse a write after the app already showed it.
    _failures = repository.writeFailures.listen(
      (_) => emit(state.copyWith(message: RecipientsMessage.failed)),
    );
    _subscription = repository
        .watchAll(uid)
        .listen(
          (list) => emit(state.copyWith(all: list, loading: false)),
          onError: (_) => emit(
            state.copyWith(loading: false, message: RecipientsMessage.failed),
          ),
        );
  }

  void search(String query) => emit(state.copyWith(query: query));

  /// Empties the search box's query. Called when the screen is left, so the
  /// next visit does not open on an old search.
  void clearSearch() => emit(state.copyWith(query: ''));

  /// Saves a new recipient and returns its id.
  ///
  /// Returns null and emits [RecipientsMessage.failed] when the number is
  /// not valid or the save fails. When the number is already saved it emits
  /// [RecipientsMessage.duplicate] and returns the existing id.
  Future<String?> add({required String name, required String phone}) async {
    final cleaned = normalisePhone(phone);
    if (cleaned == null) {
      emit(state.copyWith(message: RecipientsMessage.failed));
      return null;
    }
    final existing = _savedWithPhone(cleaned);
    if (existing != null) {
      emit(state.copyWith(message: RecipientsMessage.duplicate));
      return existing.id;
    }
    final now = DateTime.now();
    final recipient = Recipient(
      id: '',
      name: name.trim(),
      phone: cleaned,
      network: networkOf(cleaned)!,
      createdAt: now,
      updatedAt: now,
    );
    return _write(
      (uid) => repository.add(uid, recipient),
      done: RecipientsMessage.added,
    );
  }

  /// Saves a changed name or number.
  Future<void> edit(Recipient recipient) async {
    final changed = recipient.copyWith(updatedAt: DateTime.now());
    await _write(
      (uid) => repository.update(uid, changed),
      done: RecipientsMessage.updated,
    );
  }

  Future<void> delete(String recipientId) async {
    await _write(
      (uid) => repository.delete(uid, recipientId),
      done: RecipientsMessage.deleted,
    );
  }

  Future<void> toggleFavorite(Recipient recipient) async {
    final changed = recipient.copyWith(
      isFavorite: !recipient.isFavorite,
      updatedAt: DateTime.now(),
    );
    // No message: the star on screen is the confirmation.
    await _write((uid) => repository.update(uid, changed));
  }

  @override
  Future<void> close() async {
    await _stopListening();
    return super.close();
  }

  Future<void> _stopListening() async {
    final subscription = _subscription;
    final failures = _failures;
    _subscription = null;
    _failures = null;
    await subscription?.cancel();
    await failures?.cancel();
  }

  Recipient? _savedWithPhone(String phone) {
    for (final recipient in state.all) {
      if (recipient.phone == phone) return recipient;
    }
    return null;
  }

  /// Runs one repository write. Returns its result, or null after emitting
  /// [RecipientsMessage.failed]. The list is never edited here: it changes
  /// when the repository stream reports the new list.
  Future<T?> _write<T>(
    Future<T> Function(String uid) write, {
    RecipientsMessage? done,
  }) async {
    final uid = _uid;
    if (uid == null) {
      emit(state.copyWith(message: RecipientsMessage.failed));
      return null;
    }
    try {
      final result = await write(uid);
      if (done != null) emit(state.copyWith(message: done));
      return result;
    } catch (_) {
      emit(state.copyWith(message: RecipientsMessage.failed));
      return null;
    }
  }
}
