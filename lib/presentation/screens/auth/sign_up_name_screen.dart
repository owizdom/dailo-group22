import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/validators.dart';
import '../../widgets/auth/auth_form.dart';
import '../../widgets/auth/auth_page.dart';
import '../../widgets/auth/social_section.dart';
import '../../widgets/auth/switch_row.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';

/// Figma 2. First step of sign-up: first and last name.
class SignUpNameScreen extends StatefulWidget {
  const SignUpNameScreen({super.key});

  @override
  State<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends State<SignUpNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  /// Errors stay hidden until the first failed submit, then follow typing.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    Navigator.pushNamed(
      context,
      Routes.signUpDetails,
      arguments: (
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
      ),
    );
  }

  /// Goes back to Sign In: pops when that is the page below, otherwise
  /// replaces this page with it.
  void _toSignIn() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(Routes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthPage(
      title: s.authSignUpTitle,
      subtitle: s.authSignUpSubtitle,
      children: [
        AuthForm(
          formKey: _formKey,
          autovalidate: _autovalidate,
          children: [
            AppTextField(
              fieldKey: K.signUpFirstName,
              controller: _firstName,
              label: s.authFirstName,
              validator: validateName,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
            ),
            AppTextField(
              fieldKey: K.signUpLastName,
              controller: _lastName,
              label: s.authLastName,
              validator: validateName,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              autofillHints: const [AutofillHints.familyName],
            ),
            PrimaryButton(
              key: K.signUpContinue,
              label: s.continueLabel,
              onPressed: _continue,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SocialSection(googleKey: K.signUpGoogle),
        const SizedBox(height: 16),
        SwitchRow(
          prompt: s.authHaveAccount,
          linkLabel: s.authSignInTitle,
          linkKey: K.signUpToSignIn,
          onPressed: _toSignIn,
        ),
      ],
    );
  }
}
