import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/network.dart';
import '../../domain/entities/recipient.dart';
import '../../domain/entities/transaction_record.dart';
import '../../domain/logic/fee_table.dart';
import '../../domain/logic/phone_number.dart';
import '../../domain/logic/qr_payload.dart';
import '../../domain/logic/ussd_codes.dart';
import '../../domain/repositories/recipient_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/ussd_launcher.dart';

/// The steps of a payment, in order.
enum SendStep { recipient, amount, review, awaitingResult, done }

class SendMoneyState extends Equatable {
  const SendMoneyState({
    this.step = SendStep.recipient,
    this.recipient,
    this.amount = 0,
    this.comment = '',
    this.fee = 0,
    this.feeKnown = true,
    this.hint,
    this.busy = false,
    this.launchProblem,
    this.recordId,
    this.result,
    this.usedRootMenu = false,
  });

  final SendStep step;

  /// A saved recipient, or one typed or scanned just now (its id is empty).
  final Recipient? recipient;

  /// Whole francs. Zero means nothing has been entered yet.
  final int amount;
  final String comment;
  final int fee;

  /// False when DailO has no fee table for the paying network. The screen
  /// then says the operator will show the fee.
  final bool feeKnown;

  /// Set when a slightly smaller amount would cost a lower fee and the
  /// fee-warning preference is on.
  final BandHint? hint;
  final bool busy;

  /// Why the phone could not dial. Shown on the review screen.
  final UssdOutcome? launchProblem;

  /// The id of the saved transaction, once [SendMoneyCubit.confirm] ran.
  final String? recordId;

  /// What the user said happened.
  final TxStatus? result;

  /// True when the phone could only dial the network's root menu, so the
  /// user must follow the steps inside it. Set when the dialer launched.
  final bool usedRootMenu;

  int get total => amount + fee;

  bool get canReview =>
      recipient != null && amount >= minAmount && amount <= maxAmount;

  SendMoneyState copyWith({
    SendStep? step,
    Recipient? recipient,
    int? amount,
    String? comment,
    int? fee,
    bool? feeKnown,
    BandHint? hint,
    bool clearHint = false,
    bool? busy,
    UssdOutcome? launchProblem,
    bool clearLaunchProblem = false,
    String? recordId,
    TxStatus? result,
    bool? usedRootMenu,
  }) {
    return SendMoneyState(
      step: step ?? this.step,
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      comment: comment ?? this.comment,
      fee: fee ?? this.fee,
      feeKnown: feeKnown ?? this.feeKnown,
      hint: clearHint ? null : (hint ?? this.hint),
      busy: busy ?? this.busy,
      launchProblem: clearLaunchProblem
          ? null
          : (launchProblem ?? this.launchProblem),
      recordId: recordId ?? this.recordId,
      result: result ?? this.result,
      usedRootMenu: usedRootMenu ?? this.usedRootMenu,
    );
  }

  @override
  List<Object?> get props => [
    step,
    recipient,
    amount,
    comment,
    fee,
    feeKnown,
    hint?.cheaperAmount,
    hint?.saving,
    busy,
    launchProblem,
    recordId,
    result,
    usedRootMenu,
  ];
}

/// Walks one payment from choosing a recipient to the receipt.
///
/// The MoMo PIN never passes through this class. [confirm] only asks the
/// phone to dial; the operator's own dialog asks for the PIN.
class SendMoneyCubit extends Cubit<SendMoneyState> {
  SendMoneyCubit({
    required this.transactions,
    required this.recipients,
    required this.launcher,
  }) : super(const SendMoneyState());

  final TransactionRepository transactions;
  final RecipientRepository recipients;
  final UssdLauncher launcher;

  String? _uid;
  Network _from = Network.mtn;
  bool _feeWarning = true;
  List<Recipient> _saved = const [];

  /// Tells the cubit who is paying, from which network, and whether to
  /// show fee hints. Called on sign-in, on sign-out (null uid) and when a
  /// setting changes.
  void bind(
    String? uid, {
    required Network from,
    required bool feeWarning,
    List<Recipient> saved = const [],
  }) {
    _uid = uid;
    _from = from;
    _feeWarning = feeWarning;
    _saved = saved;
    emit(_priced(state));
  }

  /// Clears everything and goes back to [SendStep.recipient].
  void start() => emit(_priced(const SendMoneyState()));

  /// Picks a saved recipient and moves to [SendStep.amount].
  void chooseRecipient(Recipient recipient) {
    emit(_priced(state.copyWith(step: SendStep.amount, recipient: recipient)));
  }

  /// Picks a typed number. Returns false and changes nothing when the number
  /// is not valid. A number that matches a saved recipient picks that
  /// recipient.
  bool chooseTyped(String input) {
    final phone = normalisePhone(input);
    if (phone == null) return false;
    chooseRecipient(_recipientFor(phone, name: ''));
    return true;
  }

  /// Picks the contact in a scanned QR code. Returns false when the code
  /// is not a DailO payment code.
  bool chooseScanned(String raw) {
    final contact = decodeQr(raw);
    if (contact == null) return false;
    chooseRecipient(_recipientFor(contact.phone, name: contact.name));
    return true;
  }

  /// Sets the amount and recalculates the fee and the hint.
  void setAmount(int amount) => emit(_priced(state.copyWith(amount: amount)));

  /// Changes the amount to the cheaper one the hint suggests.
  void applyHint() {
    final hint = state.hint;
    if (hint != null) setAmount(hint.cheaperAmount);
  }

  void setComment(String comment) => emit(state.copyWith(comment: comment));

  /// Moves to [SendStep.review] when [SendMoneyState.canReview] is true.
  void toReview() {
    if (state.canReview) emit(state.copyWith(step: SendStep.review));
  }

  /// Goes back to [SendStep.amount] and keeps every detail.
  void backToAmount() {
    emit(state.copyWith(step: SendStep.amount, clearLaunchProblem: true));
  }

  /// Saves the payment as pending, then asks the phone to dial.
  ///
  /// The record is written first so nothing is lost if the app is closed
  /// during the USSD session. When the phone cannot dial, the record is
  /// marked failed, [SendMoneyState.launchProblem] is set and the step
  /// stays on review with every detail kept.
  Future<void> confirm() async {
    final uid = _uid;
    final recipient = state.recipient;
    if (uid == null || recipient == null || state.busy) return;

    emit(state.copyWith(busy: true));
    final code = _code(recipient);
    String? recordId;
    // An exception from the repository or the dialer counts as "could not
    // dial", so the user can try again instead of being stuck on busy.
    var outcome = UssdOutcome.unsupported;
    try {
      recordId = await transactions.add(uid, _pendingRecord(recipient));
      outcome = await launcher.run(code);
    } catch (_) {
      outcome = UssdOutcome.unsupported;
    }

    if (outcome == UssdOutcome.launched && recordId != null) {
      emit(
        state.copyWith(
          step: SendStep.awaitingResult,
          busy: false,
          recordId: recordId,
          clearLaunchProblem: true,
          usedRootMenu: code == rootMenuCode,
        ),
      );
      return;
    }
    await _markFailed(uid, recordId);
    emit(state.copyWith(busy: false, launchProblem: outcome));
  }

  /// Records what the user said happened and moves to [SendStep.done].
  /// A success also saves a new recipient or updates when they were
  /// last paid.
  Future<void> report(TxStatus result) async {
    final uid = _uid;
    final recipient = state.recipient;
    final recordId = state.recordId;
    if (uid == null || recipient == null || recordId == null) return;

    // The receipt is shown even when a write fails, so a repository error
    // never leaves the user on the question.
    await _ignoringErrors(() => transactions.setStatus(uid, recordId, result));
    if (result == TxStatus.success) {
      await _ignoringErrors(() => _rememberPaid(uid, recipient));
    }
    emit(state.copyWith(step: SendStep.done, result: result, busy: false));
  }

  /// Starts another payment to the same recipient.
  void payAgain() {
    final recipient = state.recipient;
    if (recipient == null) return;
    emit(_priced(SendMoneyState(step: SendStep.amount, recipient: recipient)));
  }

  /// Returns [state] with the fee and the hint worked out again for the
  /// current recipient, amount and paying network. The fee stays 0 until
  /// there is a recipient and a legal amount, and when the paying network's
  /// fee table is not known.
  SendMoneyState _priced(SendMoneyState state) {
    final recipient = state.recipient;
    final feeKnown = isFeeKnown(_from);
    final inRange = state.amount >= minAmount && state.amount <= maxAmount;
    if (recipient == null || !feeKnown || !inRange) {
      return state.copyWith(fee: 0, feeKnown: feeKnown, clearHint: true);
    }
    final to = recipient.network;
    final hint = _feeWarning
        ? bandHint(state.amount, from: _from, to: to)
        : null;
    return state.copyWith(
      fee: feeFor(state.amount, from: _from, to: to),
      feeKnown: true,
      hint: hint,
      clearHint: hint == null,
    );
  }

  /// The saved recipient with this number, or a new unsaved one (empty id).
  Recipient _recipientFor(String phone, {required String name}) {
    for (final saved in _saved) {
      if (saved.phone == phone) return saved;
    }
    final now = DateTime.now();
    return Recipient(
      id: '',
      name: name,
      phone: phone,
      network: networkOf(phone)!,
      createdAt: now,
      updatedAt: now,
    );
  }

  TransactionRecord _pendingRecord(Recipient recipient) {
    final now = DateTime.now();
    return TransactionRecord(
      id: '',
      type: TxType.send,
      recipientId: recipient.id.isEmpty ? null : recipient.id,
      counterpartyName: recipient.name,
      counterpartyPhone: recipient.phone,
      network: _from,
      amount: state.amount,
      fee: state.fee,
      comment: state.comment,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _code(Recipient recipient) {
    return sendMoneyCode(
      recipient.phone,
      state.amount,
      from: _from,
      to: recipient.network,
    );
  }

  /// Marks the saved record failed, when there is one. Never throws.
  Future<void> _markFailed(String uid, String? recordId) async {
    if (recordId == null) return;
    await _ignoringErrors(
      () => transactions.setStatus(uid, recordId, TxStatus.failed),
    );
  }

  Future<void> _ignoringErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // The caller carries on; the repository already reports refusals.
    }
  }

  /// After a confirmed payment: a saved recipient is marked as just paid,
  /// a typed or scanned one is saved so it appears in Recents next time.
  Future<void> _rememberPaid(String uid, Recipient recipient) async {
    final now = DateTime.now();
    // The server needs a name, so a number without one is saved under its
    // phone number.
    // A scanned code can carry a longer name than the server accepts
    // (a first and last name of 30 letters each make 61), so it is cut.
    final rawName = recipient.name.isEmpty ? recipient.phone : recipient.name;
    final name = rawName.length > Recipient.maxNameLength
        ? rawName.substring(0, Recipient.maxNameLength)
        : rawName;
    final paid = recipient.copyWith(
      name: name,
      lastPaidAt: now,
      updatedAt: now,
    );
    if (recipient.id.isEmpty) {
      await recipients.add(uid, paid);
    } else {
      await recipients.update(uid, paid);
    }
  }
}
