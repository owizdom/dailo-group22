import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/validators.dart';

/// The "I agree to the terms" box. A form field, so an unticked box blocks
/// the submit and shows its message underneath.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({super.key, required this.accepted});

  /// Holds whether the box is ticked. The screen owns and disposes it.
  final ValueNotifier<bool> accepted;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FormField<bool>(
      validator: (_) =>
          accepted.value ? null : s.fieldError(FieldError.termsNotAccepted),
      builder: (field) {
        void toggle() {
          accepted.value = !accepted.value;
          field.didChange(accepted.value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: accepted,
              builder: (context, ticked, _) => Row(
                children: [
                  Checkbox(
                    key: K.signUpTerms,
                    value: ticked,
                    onChanged: (_) => toggle(),
                  ),
                  Expanded(
                    child: InkWell(onTap: toggle, child: Text(s.authTerms)),
                  ),
                ],
              ),
            ),
            if (field.hasError)
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        );
      },
    );
  }
}
