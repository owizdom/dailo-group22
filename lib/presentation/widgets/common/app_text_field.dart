import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';

/// A labelled form field in the app's style.
///
/// [validator] returns a [FieldError]; this widget turns it into a polite
/// message in the user's language. Set [obscure] for a password: the field
/// then has an eye button that shows or hides the text.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.fieldKey,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscure = false,
    this.maxLines = 1,
    this.prefixText,
    this.suffixIcon,
    this.autofillHints,
    this.style,
  });

  /// Goes on the inner TextFormField so tests can type into it.
  final Key fieldKey;
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FieldError? Function(String? value)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscure;
  final int maxLines;
  final String? prefixText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;

  /// Overrides the text style, for example the large amount number.
  final TextStyle? style;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Whether a password is hidden. A ValueNotifier rebuilds only the field,
  /// so no setState is needed.
  late final ValueNotifier<bool> _hidden = ValueNotifier(widget.obscure);

  @override
  void dispose() {
    _hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<bool>(
          valueListenable: _hidden,
          builder: (context, hidden, _) {
            return TextFormField(
              key: widget.fieldKey,
              controller: widget.controller,
              obscureText: widget.obscure && hidden,
              style: widget.style,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.obscure ? 1 : widget.maxLines,
              autofillHints: widget.autofillHints,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              validator: (value) {
                final error = widget.validator?.call(value);
                return error == null ? null : strings.fieldError(error);
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixText: widget.prefixText,
                errorMaxLines: 3,
                suffixIcon: widget.obscure
                    ? IconButton(
                        tooltip: hidden ? 'Show' : 'Hide',
                        icon: Icon(
                          hidden ? Icons.visibility : Icons.visibility_off,
                          color: context.palette.mutedText,
                        ),
                        onPressed: () => _hidden.value = !hidden,
                      )
                    : widget.suffixIcon,
              ),
            );
          },
        ),
      ],
    );
  }
}
