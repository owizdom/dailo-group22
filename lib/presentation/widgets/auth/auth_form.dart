import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// A form whose errors stay hidden until the first failed submit.
///
/// The screen flips [autovalidate] after a failed submit, so from then on
/// an error clears while the user types.
class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.formKey,
    required this.autovalidate,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final ValueNotifier<AutovalidateMode> autovalidate;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AutovalidateMode>(
      valueListenable: autovalidate,
      builder: (context, mode, _) {
        return Form(
          key: formKey,
          autovalidateMode: mode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in children) ...[
                child,
                if (child != children.last)
                  const SizedBox(height: AppSizes.gap),
              ],
            ],
          ),
        );
      },
    );
  }
}
