import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/validators.dart';
import '../../cubits/auth_cubit.dart';
import '../../widgets/auth/auth_form.dart';
import '../../widgets/auth/auth_page.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/auth/social_section.dart';
import '../../widgets/auth/switch_row.dart';
import '../../widgets/common/app_text_field.dart';

/// Figma 1. Email and password sign-in, Google sign-in, links to sign-up and forgot password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Errors stay hidden until the first failed submit, then follow typing.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    context.read<AuthCubit>().signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthPage(
      title: s.authSignInTitle,
      subtitle: s.authSignInSubtitle,
      children: [
        AuthForm(
          formKey: _formKey,
          autovalidate: _autovalidate,
          children: [
            AppTextField(
              fieldKey: K.signInEmail,
              controller: _email,
              label: s.authEmail,
              hint: 'example@email.com',
              validator: validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            AppTextField(
              fieldKey: K.signInPassword,
              controller: _password,
              label: s.authPassword,
              validator: validateSignInPassword,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.password],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: K.signInForgot,
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.forgotPassword),
                child: Text(s.authForgotLink),
              ),
            ),
            AuthSubmitButton(
              key: K.signInSubmit,
              label: s.authSignInTitle,
              onPressed: _submit,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SocialSection(googleKey: K.signInGoogle),
        const SizedBox(height: 16),
        SwitchRow(
          prompt: s.authNoAccount,
          linkLabel: s.authSignUpTitle,
          linkKey: K.signInToSignUp,
          onPressed: () => Navigator.pushNamed(context, Routes.signUpName),
        ),
      ],
    );
  }
}
