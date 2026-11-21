import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../cubits/auth_cubit.dart';
import '../../widgets/auth/auth_form.dart';
import '../../widgets/auth/auth_message_listener.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/section_card.dart';

/// Sends a password reset email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// Errors stay hidden until the first failed submit, then follow typing.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _email.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    context.read<AuthCubit>().sendPasswordReset(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthMessageListener(
      child: AppPage(
        title: s.authForgotTitle,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.authForgotBody,
                  style: TextStyle(color: context.palette.mutedText),
                ),
                const SizedBox(height: AppSizes.gap),
                AuthForm(
                  formKey: _formKey,
                  autovalidate: _autovalidate,
                  children: [
                    AppTextField(
                      fieldKey: K.forgotEmail,
                      controller: _email,
                      label: s.authEmail,
                      hint: 'example@email.com',
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.email],
                    ),
                    AuthSubmitButton(
                      key: K.forgotSubmit,
                      label: s.authSendReset,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
