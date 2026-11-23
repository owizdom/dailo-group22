import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../cubits/top_up_cubit.dart';
import '../common/app_page.dart';
import '../common/app_text_field.dart';
import '../common/buttons.dart';
import '../common/result_question.dart';
import '../common/section_card.dart';
import '../common/snack.dart';
import '../common/ussd_steps_notice.dart';

/// The page behind Buy Airtime and Buy Data: an amount form, then the
/// "did it work?" question once the phone has dialled.
///
/// Only the words, the keys and the optional phone field differ between the
/// two screens, so they are passed in.
class TopUpPage extends StatefulWidget {
  const TopUpPage({
    super.key,
    required this.type,
    required this.title,
    required this.amountKey,
    required this.amountLabel,
    required this.buyKey,
    required this.buyLabel,
    this.intro,
    this.phoneKey,
  });

  /// [TxType.airtime] or [TxType.data].
  final TxType type;
  final String title;
  final Key amountKey;
  final String amountLabel;
  final Key buyKey;
  final String buyLabel;

  /// A line of explanation above the amount field.
  final String? intro;

  /// When set, the form also asks for another number to buy for.
  final Key? phoneKey;

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void initState() {
    super.initState();
    // The cubit is shared by both screens. Clear what an earlier visit left
    // behind, such as a "no SIM" notice.
    context.read<TopUpCubit>().reset();
  }

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TopUpCubit, TopUpState>(
      listenWhen: (before, after) => after.result != null,
      listener: _finish,
      builder: (context, state) {
        return AppPage(
          title: widget.title,
          children: [
            if (state.awaitingResult)
              SectionCard(
                child: ResultQuestion(
                  onAnswer: context.read<TopUpCubit>().report,
                  steps: state.usedRootMenu ? _stepsFor(state) : null,
                ),
              )
            else ...[
              _buildForm(context, state),
              if (state.launchProblem != null) ...[
                const SizedBox(height: AppSizes.gap),
                LaunchProblemNotice(outcome: state.launchProblem!),
              ],
            ],
          ],
        );
      },
    );
  }

  /// What to do in the network's menu, repeating what was just asked for.
  Widget _stepsFor(TopUpState state) {
    return UssdStepsNotice(
      type: widget.type,
      amount: state.amount,
      phone: state.forPhone,
    );
  }

  Widget _buildForm(BuildContext context, TopUpState state) {
    final intro = widget.intro;
    return SectionCard(
      child: ValueListenableBuilder<AutovalidateMode>(
        valueListenable: _autovalidate,
        builder: (context, mode, _) => Form(
          key: _formKey,
          autovalidateMode: mode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (intro != null) ...[
                Text(intro, style: TextStyle(color: context.palette.mutedText)),
                const SizedBox(height: AppSizes.gap),
              ],
              AppTextField(
                fieldKey: widget.amountKey,
                label: widget.amountLabel,
                hint: context.s.topUpAmountHint,
                controller: _amount,
                validator: validateAmount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (widget.phoneKey != null) ...[
                const SizedBox(height: AppSizes.gap),
                AppTextField(
                  fieldKey: widget.phoneKey!,
                  label: context.s.airtimePhoneLabel,
                  hint: context.s.airtimePhoneHint,
                  controller: _phone,
                  validator: _validateOptionalPhone,
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: AppSizes.gap),
              PrimaryButton(
                key: widget.buyKey,
                label: widget.buyLabel,
                busy: state.busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty means "this line", so only a typed number is checked.
  FieldError? _validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validatePhone(value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    final phone = _phone.text.trim();
    context.read<TopUpCubit>().buy(
      type: widget.type,
      amount: parseAmount(_amount.text)!,
      forPhone: phone.isEmpty ? null : phone,
    );
  }

  /// The user answered: say it was saved, clear the cubit and go back.
  void _finish(BuildContext context, TopUpState state) {
    showSnack(context, context.s.purchaseSaved);
    context.read<TopUpCubit>().reset();
    Navigator.pop(context);
  }
}
