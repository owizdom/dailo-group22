import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../cubits/feedback_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/snack.dart';
import '../../widgets/home/star_rating.dart';

/// A star rating and a message sent to the DailO team.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _rating = ValueNotifier(5);

  /// Errors stay hidden until the first failed submit.
  final _autovalidate = ValueNotifier(AutovalidateMode.disabled);

  @override
  void dispose() {
    _message.dispose();
    _rating.dispose();
    _autovalidate.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) {
      _autovalidate.value = AutovalidateMode.onUserInteraction;
      return;
    }
    context.read<FeedbackCubit>().send(
      message: _message.text.trim(),
      rating: _rating.value,
    );
  }

  void _onMessage(BuildContext context, FeedbackState state) {
    final strings = context.s;
    if (state.message == FeedbackMessage.sent) {
      showSnack(context, strings.feedbackSent);
      Navigator.pop(context);
    } else {
      showSnack(context, strings.feedbackSendFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (_, state) => state.message != null,
      listener: _onMessage,
      child: AppPage(
        title: strings.feedbackTitle,
        children: [
          // One list item, so every control is built even in landscape.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.feedbackRatingLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    StarRating(rating: _rating),
                    const SizedBox(height: AppSizes.gap),
                    ValueListenableBuilder<AutovalidateMode>(
                      valueListenable: _autovalidate,
                      builder: (context, mode, _) => Form(
                        key: _formKey,
                        autovalidateMode: mode,
                        child: AppTextField(
                          fieldKey: K.feedbackMessage,
                          controller: _message,
                          label: strings.feedbackMessageLabel,
                          hint: strings.feedbackMessageHint,
                          validator: validateFeedback,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.gap),
              BlocSelector<FeedbackCubit, FeedbackState, bool>(
                selector: (state) => state.busy,
                builder: (context, busy) => PrimaryButton(
                  key: K.feedbackSubmit,
                  label: strings.feedbackSend,
                  busy: busy,
                  onPressed: _send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}