import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/network.dart';
import '../../domain/repositories/profile_repository.dart';

/// A one-off result to show in a snack bar.
enum ProfileMessage { saved, failed }

class ProfileState extends Equatable {
  const ProfileState({this.user, this.saving = false, this.message});

  /// Null until the profile document has loaded, and after sign-out.
  final AppUser? user;
  final bool saving;

  /// Set for one state only.
  final ProfileMessage? message;

  @override
  List<Object?> get props => [user, saving, message];
}

/// Shows and edits the signed-in user's profile.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.repository) : super(const ProfileState());

  final ProfileRepository repository;
  StreamSubscription<AppUser?>? _subscription;
  StreamSubscription<void>? _failures;

  /// Starts following the profile of [uid]. Pass null on sign-out to stop
  /// listening and clear the state.
  void watch(String? uid) {
    _stopListening();
    if (uid == null) {
      emit(const ProfileState());
      return;
    }
    // The server can refuse a write after the app already showed it.
    _failures = repository.writeFailures.listen(
      (_) => emit(
        ProfileState(
          user: state.user,
          saving: state.saving,
          message: ProfileMessage.failed,
        ),
      ),
    );
    _subscription = repository
        .watch(uid)
        .listen((user) => emit(ProfileState(user: user, saving: state.saving)));
  }

  /// Saves the edited profile. Does nothing when no profile is loaded.
  Future<void> save({
    required String firstName,
    required String lastName,
    required String phone,
    required Network network,
  }) async {
    final user = state.user;
    if (user == null) return;

    emit(ProfileState(user: user, saving: true));
    final edited = user.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      network: network,
      updatedAt: DateTime.now(),
    );
    try {
      await repository.update(edited);
      emit(ProfileState(user: state.user, message: ProfileMessage.saved));
    } catch (_) {
      emit(ProfileState(user: state.user, message: ProfileMessage.failed));
    }
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
}
