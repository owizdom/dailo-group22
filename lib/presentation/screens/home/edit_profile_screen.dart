import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/profile_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/snack.dart';

/// Change the first name, last name and phone number.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;

  /// Errors stay hidden until the first failed submit.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileCubit>().state.user;
    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _phone = TextEditingController(
      text: user == null ? null : prettyPhone(user.phone),
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    final cubit = context.read<ProfileCubit>();
    final phone = normalisePhone(_phone.text)!;
    cubit.save(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: phone,
      network: networkOf(phone) ?? cubit.state.user!.network,
    );
  }

  void _onMessage(BuildContext context, ProfileState state) {
    final strings = context.s;
    if (state.message == ProfileMessage.saved) {
      showSnack(context, strings.profileSaved);
      Navigator.pop(context);
    } else {
      showSnack(context, strings.profileSaveFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (_, state) => state.message != null,
      listener: _onMessage,
      child: AppPage(
        title: strings.profileTitle,
        children: [
          // One list item, so every control is built even in landscape.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                child: ValueListenableBuilder<AutovalidateMode>(
                  valueListenable: _autovalidate,
                  builder: (context, mode, _) => Form(
                    key: _formKey,
                    autovalidateMode: mode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          fieldKey: K.profileFirstName,
                          controller: _firstName,
                          label: strings.profileFirstName,
                          validator: validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSizes.gap),
                        AppTextField(
                          fieldKey: K.profileLastName,
                          controller: _lastName,
                          label: strings.profileLastName,
                          validator: validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSizes.gap),
                        AppTextField(
                          fieldKey: K.profilePhone,
                          controller: _phone,
                          label: strings.phoneNumber,
                          validator: validatePhone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.gap),
              BlocSelector<ProfileCubit, ProfileState, bool>(
                selector: (state) => state.saving,
                builder: (context, saving) => PrimaryButton(
                  key: K.profileSave,
                  label: strings.save,
                  busy: saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
