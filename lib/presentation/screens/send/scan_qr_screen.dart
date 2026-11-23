import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../cubits/send_money_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/snack.dart';

/// Builds the camera view. It must call [onCode] with the raw text of each
/// QR code it reads.
typedef ScannerBuilder = Widget Function(void Function(String raw) onCode);

/// Figma 7. Camera scanner for a DailO payment QR code.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key, this.scannerBuilder});

  /// Null uses the real camera. Tests pass a fake that calls `onCode`.
  final ScannerBuilder? scannerBuilder;

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  /// True once a valid code was taken. A camera reports the same code on
  /// many frames, and only the first one may open the amount screen.
  final _accepted = ValueNotifier(false);

  @override
  void dispose() {
    _accepted.dispose();
    super.dispose();
  }

  void _onCode(String raw) {
    if (_accepted.value) return;
    if (context.read<SendMoneyCubit>().chooseScanned(raw)) {
      _accepted.value = true;
      Navigator.pushReplacementNamed(context, Routes.amount);
    } else {
      showSnack(context, context.s.scanInvalid, error: true);
    }
  }

  /// MobileScanner opens and closes its own camera controller.
  Widget _camera() {
    final builder = widget.scannerBuilder;
    if (builder != null) return builder(_onCode);
    return MobileScanner(
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw != null) _onCode(raw);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return AppPage(
      title: strings.sendMoney,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.scanTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.scanHelp,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.mutedText),
              ),
              const SizedBox(height: 16),
              _CameraFrame(child: _camera()),
              const SizedBox(height: 16),
              PrimaryButton(
                key: K.scanManual,
                label: strings.scanManual,
                onPressed: () => Navigator.maybePop(context),
              ),
              Center(
                child: TextButton(
                  key: K.scanMyCode,
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.generateQr),
                  child: Text(
                    strings.scanMyCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A rounded square, at most 280 wide, that clips the camera view.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
