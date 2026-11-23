import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction_record.dart';
import '../../domain/repositories/transaction_repository.dart';

/// A one-off result to show in a snack bar.
enum TransactionsMessage { updated, deleted, failed }

class TransactionsState extends Equatable {
  const TransactionsState({
    this.all = const [],
    this.query = '',
    this.filter,
    this.loading = false,
    this.message,
  });

  /// Every record, newest first, as last reported by the repository.
  final List<TransactionRecord> all;
  final String query;

  /// Null shows every type.
  final TxType? filter;
  final bool loading;

  /// Set for one state only.
  final TransactionsMessage? message;

  /// [all] narrowed by [filter] and [query]. The query matches the name,
  /// the phone number or the comment.
  List<TransactionRecord> get visible {
    final text = query.trim().toLowerCase();
    final digits = text.replaceAll(RegExp(r'\s'), '');
    return all.where((record) {
      if (filter != null && record.type != filter) return false;
      if (text.isEmpty) return true;
      return record.counterpartyName.toLowerCase().contains(text) ||
          record.counterpartyPhone.contains(digits) ||
          record.comment.toLowerCase().contains(text);
    }).toList();
  }

  /// The five newest records, for the Home screen.
  List<TransactionRecord> get recent => all.take(5).toList();

  TransactionsState copyWith({
    List<TransactionRecord>? all,
    String? query,
    TxType? filter,
    bool clearFilter = false,
    bool? loading,
    TransactionsMessage? message,
  }) {
    return TransactionsState(
      all: all ?? this.all,
      query: query ?? this.query,
      filter: clearFilter ? null : (filter ?? this.filter),
      loading: loading ?? this.loading,
      message: message,
    );
  }

  @override
  List<Object?> get props => [all, query, filter, loading, message];
}

/// The transaction history: read, search, filter, correct a result, delete.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit(this.repository) : super(const TransactionsState());

  final TransactionRepository repository;
  StreamSubscription<List<TransactionRecord>>? _subscription;
  StreamSubscription<void>? _failures;
  String? _uid;

  /// Starts following the records of [uid]. Pass null on sign-out to stop
  /// listening and clear the list.
  void watch(String? uid) {
    _stopListening();
    _uid = uid;
    if (uid == null) {
      emit(const TransactionsState());
      return;
    }
    emit(state.copyWith(loading: true));
    // The server can refuse a write after the app already showed it.
    _failures = repository.writeFailures.listen(
      (_) => emit(state.copyWith(message: TransactionsMessage.failed)),
    );
    _subscription = repository
        .watchAll(uid)
        .listen(
          (list) => emit(state.copyWith(all: list, loading: false)),
          onError: (_) => emit(
            state.copyWith(loading: false, message: TransactionsMessage.failed),
          ),
        );
  }

  void search(String query) => emit(state.copyWith(query: query));

  /// Empties the query and shows every type again. Called when the History
  /// screen is left, so the next visit does not open on an old search.
  void clearSearch() => emit(state.copyWith(query: '', clearFilter: true));

  /// Pass null to show every type again.
  void setFilter(TxType? type) =>
      emit(state.copyWith(filter: type, clearFilter: type == null));

  /// Corrects what happened to a payment, for example a pending one the
  /// SMS later confirmed.
  Future<void> setStatus(String recordId, TxStatus status) => _write(
    (uid) => repository.setStatus(uid, recordId, status),
    done: TransactionsMessage.updated,
  );

  Future<void> delete(String recordId) => _write(
    (uid) => repository.delete(uid, recordId),
    done: TransactionsMessage.deleted,
  );

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

  /// Runs one repository write and reports the outcome as a message. The
  /// list changes when the repository stream reports the new list.
  Future<void> _write(
    Future<void> Function(String uid) write, {
    required TransactionsMessage done,
  }) async {
    final uid = _uid;
    if (uid == null) {
      emit(state.copyWith(message: TransactionsMessage.failed));
      return;
    }
    try {
      await write(uid);
      emit(state.copyWith(message: done));
    } catch (_) {
      emit(state.copyWith(message: TransactionsMessage.failed));
    }
  }
}
