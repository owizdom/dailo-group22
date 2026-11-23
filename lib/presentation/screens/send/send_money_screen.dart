import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../cubits/send_money_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/send/recent_recipients_card.dart';

/// Figma 6. Type a number, scan a code, or pick from Recents and Favorites.
class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  /// Errors stay hidden until the first failed submit.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _phone.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    final chosen = context.read<SendMoneyCubit>().chooseTyped(_phone.text);
    if (chosen) Navigator.pushNamed(context, Routes.amount);
  }

  /// The number field with the scan button beside it, as in the design.
  Widget _numberRow(AppStrings strings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            fieldKey: K.sendPhone,
            controller: _phone,
            label: strings.sendEnterNumber,
            hint: '07xxxxxxxx',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: validatePhone,
            onSubmitted: (_) => _continue(),
          ),
        ),
        const SizedBox(width: 10),
        _ScanButton(
          tooltip: strings.sendScanTooltip,
          onPressed: () => Navigator.pushNamed(context, Routes.scanQr),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AppPage(
      title: strings.sendMoney,
      children: [
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
                      _numberRow(strings),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        key: K.sendContinue,
                        label: strings.continueLabel,
                        onPressed: _continue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecentRecipientsCard(
              onPick: (recipient) {
                context.read<SendMoneyCubit>().chooseRecipient(recipient);
                Navigator.pushNamed(context, Routes.amount);
              },
              onViewAll: () => Navigator.pushNamed(context, Routes.recipients),
            ),
          ],
        ),
      ],
    );
  }
}

/// The square QR scan button next to the number field.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton.outlined(
        key: K.sendScan,
        tooltip: tooltip,
        icon: const Icon(Icons.qr_code_scanner),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
