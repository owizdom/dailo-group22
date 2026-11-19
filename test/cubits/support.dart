import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets every queued stream event reach the cubit and its listeners.
///
/// Repository streams deliver their events a moment after a write. Call this
/// before reading `cubit.state` or the list made by [record].
Future<void> settle() => pumpEventQueue();

/// Remembers every state [cubit] emits from now on, oldest first.
///
/// The cubit's current state is not in the list. Call [settle] before
/// reading it, because a cubit's stream delivers states a moment late.
List<S> record<S>(BlocBase<S> cubit) {
  final states = <S>[];
  cubit.stream.listen(states.add);
  return states;
}