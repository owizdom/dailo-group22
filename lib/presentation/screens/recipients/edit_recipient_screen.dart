import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../domain/entities/recipient.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/recipients_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/recipients/recipients_message_listener.dart';

/// Figma 11. Adds a recipient, or edits [recipient] when one is given.
class EditRecipientScreen extends StatefulWidget {
  const EditRecipientScreen({super.key, this.recipient});

  /// Null means a new recipient is being added.
  final Recipient? recipient;

  @override
  State<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends State<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.recipient?.name);
  late final _phone = TextEditingController(text: widget.recipient?.phone);

  /// Errors stay hidden until the first failed save, then follow typing.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    final cubit = context.read<RecipientsCubit>();
    final phone = normalisePhone(_phone.text)!;
    final existing = widget.recipient;
    if (existing == null) {
      await cubit.add(name: _name.text, phone: phone);
    } else {
      await cubit.edit(
        existing.copyWith(
          name: _name.text.trim(),
          phone: phone,
          network: networkOf(phone) ?? existing.network,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final adding = widget.recipient == null;
    return RecipientsMessageListener(
      child: BlocListener<RecipientsCubit, RecipientsState>(
        listenWhen: (before, after) => _isSaved(after.message),
        listener: (context, state) => Navigator.maybePop(context),
        child: AppPage(
          title: adding ? s.addRecipientTitle : s.editRecipientTitle,
          children: [SectionCard(child: _form(s))],
        ),
      ),
    );
  }

  bool _isSaved(RecipientsMessage? message) {
    return message == RecipientsMessage.added ||
        message == RecipientsMessage.updated;
  }

  Widget _form(AppStrings s) {
    return ValueListenableBuilder<AutovalidateMode>(
      valueListenable: _autovalidate,
      builder: (context, mode, _) {
        return Form(
          key: _formKey,
          autovalidateMode: mode,
          child: Column(
            children: [
              AppTextField(
                fieldKey: K.editName,
                controller: _name,
                label: s.name,
                hint: s.recipientNameHint,
                validator: validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.gap),
              AppTextField(
                fieldKey: K.editPhone,
                controller: _phone,
                label: s.phoneNumber,
                hint: '07xxxxxxxx',
                validator: validatePhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.gap),
              PrimaryButton(key: K.editSave, label: s.save, onPressed: _save),
            ],
          ),
        );
      },
    );
  }
}
