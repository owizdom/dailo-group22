import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/network.dart';
import '../../domain/entities/transaction_record.dart';
import '../../domain/logic/phone_number.dart';
import '../../domain/logic/ussd_codes.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/ussd_launcher.dart';

class TopUpState extends Equatable {
  const TopUpState({
    this.busy = false,
    this.awaitingResult = false,
    this.launchProblem,
    this.recordId,
    this.result,
    this.usedRootMenu = false,
    this.amount = 0,
    this.forPhone = '',
  });

  final bool busy;

  /// True after the phone dialled, until the user says what happened.
  final bool awaitingResult;
  final UssdOutcome? launchProblem;
  final String? recordId;
  final TxStatus? result;

  /// True when the phone could only dial the network's root menu, so the
  /// user must follow the steps inside it.
  final bool usedRootMenu;

  /// What was bought, kept so the steps notice can repeat it.
  final int amount;

  /// The normalised other number, or '' for the user's own line.
  final String forPhone;

  @override
  List<Object?> get props => [
    busy,
    awaitingResult,
    launchProblem,
    recordId,
    result,
    usedRootMenu,
    amount,
    forPhone,
  ];
}

/// Buys airtime or data: saves the purchase, dials the code, then records
/// what the user said happened.
class TopUpCubit extends Cubit<TopUpState> {
  TopUpCubit({required this.transactions, required this.launcher})
    : super(const TopUpState());

  final TransactionRepository transactions;
  final UssdLauncher launcher;
  String? _uid;
  Network _network = Network.mtn;

  /// Tells the cubit who is buying and on which network.
  void bind(String? uid, {required Network network}) {
    _uid = uid;
    _network = network;
  }

  /// [type] must be [TxType.airtime] or [TxType.data]. [forPhone] is only
  /// used for airtime bought for someone else.
  Future<void> buy({
    required TxType type,
    required int amount,
    String? forPhone,
  }) async {
    if (type == TxType.send) {
      throw ArgumentError.value(type, 'type', 'a send has its own flow');
    }
    final uid = _uid;
    if (uid == null || state.busy) return;

    emit(const TopUpState(busy: true));
    final phone = _otherNumber(forPhone);
    final code = _codeFor(type, amount, phone);
    String? recordId;
    // An exception from the repository or the dialer counts as "could not
    // dial", so the user can try again instead of being stuck on busy.
    var outcome = UssdOutcome.unsupported;
    try {
      // Saved first so nothing is lost if the app closes during the USSD
      // session.
      recordId = await transactions.add(
        uid,
        _pendingRecord(type, amount, phone),
      );
      outcome = await launcher.run(code);
    } catch (_) {
      outcome = UssdOutcome.unsupported;
    }

    if (outcome == UssdOutcome.launched && recordId != null) {
      emit(
        TopUpState(
          awaitingResult: true,
          recordId: recordId,
          usedRootMenu: code == rootMenuCode,
          amount: amount,
          forPhone: phone,
        ),
      );
      return;
    }
    await _markFailed(uid, recordId);
    emit(TopUpState(launchProblem: outcome));
  }

  Future<void> report(TxStatus result) async {
    final uid = _uid;
    final recordId = state.recordId;
    if (uid == null || recordId == null) return;

    // The answer is shown as saved even when the write fails, so an error
    // never leaves the user on the question.
    try {
      await transactions.setStatus(uid, recordId, result);
    } catch (_) {
      // Nothing more to do here; the repository reports refusals itself.
    }
    emit(TopUpState(recordId: recordId, result: result));
  }

  /// Clears the state for the next purchase.
  void reset() => emit(const TopUpState());

  /// The other number in `07XXXXXXXX` form, or '' for the user's own line.
  String _otherNumber(String? typed) {
    if (typed == null || typed.trim().isEmpty) return '';
    return normalisePhone(typed) ?? '';
  }

  /// Marks the saved record failed, when there is one. Never throws.
  Future<void> _markFailed(String uid, String? recordId) async {
    if (recordId == null) return;
    try {
      await transactions.setStatus(uid, recordId, TxStatus.failed);
    } catch (_) {
      // The user still sees the problem notice.
    }
  }

  TransactionRecord _pendingRecord(TxType type, int amount, String phone) {
    final now = DateTime.now();
    return TransactionRecord(
      id: '',
      type: type,
      counterpartyName: '',
      counterpartyPhone: phone,
      network: _network,
      amount: amount,
      fee: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _codeFor(TxType type, int amount, String phone) {
    if (type == TxType.airtime) {
      return airtimeCode(
        amount,
        forPhone: phone.isEmpty ? null : phone,
        network: _network,
      );
    }
    return dataMenuCode(_network);
  }
}