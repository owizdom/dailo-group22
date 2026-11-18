import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth_cubit.dart';
import '../common/buttons.dart';

/// The navy button of an auth screen. It shows a spinner while the cubit is
/// busy.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthState, bool>(
      selector: (state) => state.busy,
      builder: (context, busy) =>
          PrimaryButton(label: label, onPressed: onPressed, busy: busy),
    );
  }
}
