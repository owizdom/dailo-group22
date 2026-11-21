import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../domain/entities/recipient.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/send_money_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/avatar.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/send/amount_chips.dart';
import '../../widgets/send/fee_summary.dart';

/// Figma 14. Amount, quick amounts, live fee and total, fee band warning, comment.
class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _comment;

  /// Errors stay hidden until the first failed submit.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void initState() {
    super.initState();
    // Coming back from Review keeps what the user already typed.
    final state = context.read<SendMoneyCubit>().state;
    _amount = TextEditingController(
      text: state.amount > 0 ? '${state.amount}' : '',
    );
    _comment = TextEditingController(text: state.comment);
  }

  @override
  void dispose() {
    _amount.dispose();
    _comment.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  /// A chip or the cheaper-amount hint changed the amount in the cubit, so
  /// the field must show it. Typing never reaches this: the field already
  /// holds the same number.
  void _showAmountInField(SendMoneyState state) {
    if ((parseAmount(_amount.text) ?? 0) != state.amount) {
      _amount.text = state.amount > 0 ? '${state.amount}' : '';
    }
  }

  void _review() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    context.read<SendMoneyCubit>().toReview();
    Navigator.pushNamed(context, Routes.review);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final cubit = context.read<SendMoneyCubit>();
    return BlocListener<SendMoneyCubit, SendMoneyState>(
      listenWhen: (before, after) => before.amount != after.amount,
      listener: (context, state) => _showAmountInField(state),
      child: AppPage(
        title: strings.sendMoney,
        children: [
          ValueListenableBuilder<AutovalidateMode>(
            valueListenable: _autovalidate,
            builder: (context, mode, _) => Form(
              key: _formKey,
              autovalidateMode: mode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RecipientCard(),
                  const SizedBox(height: AppSizes.gap),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          fieldKey: K.amountField,
                          controller: _amount,
                          label: strings.amount,
                          hint: strings.amountPlaceholder,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: validateAmount,
                          onChanged: (text) =>
                              cubit.setAmount(parseAmount(text) ?? 0),
                          style: _amountStyle,
                          suffixIcon: const _FrwSuffix(),
                        ),
                        const SizedBox(height: AppSizes.gap),
                        AmountChips(onPick: cubit.setAmount),
                        const SizedBox(height: 4),
                        const FeeSummary(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.gap),
                  SectionCard(
                    child: _CommentField(
                      controller: _comment,
                      onChanged: cubit.setComment,
                    ),
                  ),
                  const SizedBox(height: AppSizes.gap),
                  PrimaryButton(
                    key: K.amountReview,
                    label: strings.reviewPayment,
                    onPressed: _review,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The amount number is large and bold, as in the design.
const _amountStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

/// "Frw" at the end of the amount field.
class _FrwSuffix extends StatelessWidget {
  const _FrwSuffix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        widthFactor: 1,
        child: Text(
          'Frw',
          style: TextStyle(
            color: context.palette.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The optional note, under a label that says it is optional.
class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AppTextField(
      fieldKey: K.amountComment,
      controller: controller,
      label: '${strings.sendComment} ${strings.sendOptional}',
      hint: strings.commentHint,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
    );
  }
}

/// Who is being paid: avatar, name, network, number and a star for a favourite.
class _RecipientCard extends StatelessWidget {
  const _RecipientCard();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SendMoneyCubit, SendMoneyState, Recipient?>(
      selector: (state) => state.recipient,
      builder: (context, recipient) {
        if (recipient == null) return const SizedBox.shrink();
        return SectionCard(
          key: K.amountRecipient,
          child: Row(
            children: [
              Avatar.initials(recipient.displayName, size: 52),
              const SizedBox(width: AppSizes.gap),
              Expanded(child: _RecipientLines(recipient: recipient)),
            ],
          ),
        );
      },
    );
  }
}

class _RecipientLines extends StatelessWidget {
  const _RecipientLines({required this.recipient});

  final Recipient recipient;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.palette.mutedText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipient.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            Flexible(
              child: Text(
                '${recipient.network.label} · ${prettyPhone(recipient.phone)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
            if (recipient.isFavorite) ...[
              const SizedBox(width: 6),
              Icon(Icons.star, size: 16, color: context.palette.mutedText),
            ],
          ],
        ),
      ],
    );
  }
}
