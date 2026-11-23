import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/validators.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/auth_cubit.dart';
import '../../widgets/auth/auth_form.dart';
import '../../widgets/auth/auth_message_listener.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/auth/terms_checkbox.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';

/// Figma 3. Second step of sign-up: email, phone, password, terms.
class SignUpDetailsScreen extends StatefulWidget {
  const SignUpDetailsScreen({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  final String firstName;
  final String lastName;

  @override
  State<SignUpDetailsScreen> createState() => _SignUpDetailsScreenState();
}

class _SignUpDetailsScreenState extends State<SignUpDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _termsAccepted = ValueNotifier(false);

  /// Errors stay hidden until the first failed submit, then follow typing.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _termsAccepted.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    context.read<AuthCubit>().signUp(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: _email.text.trim(),
      phone: normalisePhone(_phone.text)!,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AuthMessageListener(
      child: AppPage(
        title: s.authSignUpTitle,
        children: [
          AuthForm(
            formKey: _formKey,
            autovalidate: _autovalidate,
            children: [
              AppTextField(
                underlined: true,
                fieldKey: K.signUpEmail,
                controller: _email,
                label: s.authEmail,
                hint: 'example@email.com',
                validator: validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              AppTextField(
                underlined: true,
                fieldKey: K.signUpPhone,
                controller: _phone,
                label: s.phoneNumber,
                hint: '07xxxxxxxx',
                validator: validatePhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              AppTextField(
                underlined: true,
                fieldKey: K.signUpPassword,
                controller: _password,
                label: s.authPassword,
                validator: validatePassword,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              AppTextField(
                underlined: true,
                fieldKey: K.signUpConfirm,
                controller: _confirm,
                label: s.authConfirmPassword,
                validator: (value) =>
                    validateConfirmPassword(value, _password.text),
                obscure: true,
                textInputAction: TextInputAction.done,
              ),
              TermsCheckbox(accepted: _termsAccepted),
              AuthSubmitButton(
                key: K.signUpSubmit,
                label: s.authSignUpTitle,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
