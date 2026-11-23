import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/feedback_note.dart';
import '../../domain/repositories/feedback_repository.dart';

/// A one-off result to show in a snack bar.
enum FeedbackMessage { sent, failed }

class FeedbackState extends Equatable {
  const FeedbackState({this.busy = false, this.message});

  final bool busy;

  /// Set for one state only.
  final FeedbackMessage? message;

  @override
  List<Object?> get props => [busy, message];
}

/// Sends the Feedback form.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this.repository) : super(const FeedbackState());

  final FeedbackRepository repository;
  StreamSubscription<void>? _failures;
  String? _uid;

  /// Tells the cubit who is signed in. Null on sign-out. While someone is
  /// signed in, a write the server refused later is reported as failed.
  void bind(String? uid) {
    _uid = uid;
    _failures?.cancel();
    _failures = null;
    if (uid == null) return;
    _failures = repository.writeFailures.listen(
      (_) => emit(const FeedbackState(message: FeedbackMessage.failed)),
    );
  }

  Future<void> send({required String message, required int rating}) async {
    final uid = _uid;
    if (uid == null) {
      emit(const FeedbackState(message: FeedbackMessage.failed));
      return;
    }
    emit(const FeedbackState(busy: true));
    final note = FeedbackNote(
      message: message.trim(),
      rating: rating,
      createdAt: DateTime.now(),
    );
    try {
      await repository.send(uid, note);
      emit(const FeedbackState(message: FeedbackMessage.sent));
    } catch (_) {
      emit(const FeedbackState(message: FeedbackMessage.failed));
    }
  }

  @override
  Future<void> close() async {
    await _failures?.cancel();
    return super.close();
  }
}
