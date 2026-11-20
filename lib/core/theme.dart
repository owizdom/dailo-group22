import 'package:flutter/material.dart';

/// Colours measured from the Figma frames.
class AppColors {
  static const navy = Color(0xFF060058);
  static const navyBright = Color(0xFF2B1BD8);
  static const page = Color(0xFFF5F5F5);
  static const field = Color(0xFFF1F1F5);
  static const lavender = Color(0xFFDCD9F5);
  static const mutedText = Color(0xFF5F5C8A);
  static const warningFill = Color(0xFFFFF4E5);
  static const warningText = Color(0xFF7A4100);
  static const successText = Color(0xFF137333);
  static const successFill = Color(0xFFE6F4EA);
  static const errorText = Color(0xFFB3261E);
}

/// Colours the Material colour scheme has no slot for. Read them with
/// `context.palette.warningFill`.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.field,
    required this.mutedText,
    required this.warningFill,
    required this.warningText,
    required this.successFill,
    required this.successText,
    required this.secondaryButton,
    required this.onSecondaryButton,
  });

  final Color field;
  final Color mutedText;
  final Color warningFill;
  final Color warningText;
  final Color successFill;
  final Color successText;
  final Color secondaryButton;
  final Color onSecondaryButton;

  static const light = AppPalette(
    field: AppColors.field,
    mutedText: AppColors.mutedText,
    warningFill: AppColors.warningFill,
    warningText: AppColors.warningText,
    successFill: AppColors.successFill,
    successText: AppColors.successText,
    secondaryButton: AppColors.lavender,
    onSecondaryButton: AppColors.navy,
  );

  static const dark = AppPalette(
    field: Color(0xFF23234A),
    mutedText: Color(0xFFC3C1DE),
    warningFill: Color(0xFF4A3200),
    warningText: Color(0xFFFFDDAA),
    successFill: Color(0xFF0F3D1E),
    successText: Color(0xFFA8E6B8),
    secondaryButton: Color(0xFF34346B),
    onSecondaryButton: Color(0xFFEDEDF7),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    return t < 0.5 ? this : (other as AppPalette? ?? this);
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Spacing and shape used on every screen, so screens never invent numbers.
class AppSizes {
  static const pagePadding = 20.0;
  static const cardRadius = 18.0;
  static const fieldRadius = 12.0;
  static const gap = 12.0;

  /// Material's minimum touch target is 48. Buttons use 52 like the Figma.
  static const buttonHeight = 52.0;
}

ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.navyBright,
    onSecondary: Colors.white,
    error: AppColors.errorText,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.navy,
  );
  return _build(scheme, AppColors.page, AppPalette.light);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFC7C4FF),
    onPrimary: AppColors.navy,
    secondary: Color(0xFFA9A4FF),
    onSecondary: AppColors.navy,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF17173A),
    onSurface: Color(0xFFEDEDF7),
  );
  return _build(scheme, const Color(0xFF0B0B1E), AppPalette.dark);
}

ThemeData _build(ColorScheme scheme, Color page, AppPalette palette) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: page,
    extensions: [palette],
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
  );
  const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: buttonShape,
        textStyle: buttonText,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: palette.mutedText),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.field,
      hintStyle: TextStyle(color: palette.mutedText),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(
      color: palette.mutedText.withValues(alpha: 0.25),
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : palette.field,
      ),
    ),
  );
}
