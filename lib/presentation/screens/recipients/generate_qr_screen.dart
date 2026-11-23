import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/logic/phone_number.dart';
import '../../../domain/logic/qr_payload.dart';
import '../../cubits/profile_cubit.dart';
import '../../widgets/common/app_page.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/section_card.dart';

/// Shows the user's own payment QR code.
class GenerateQrScreen extends StatelessWidget {
  const GenerateQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((ProfileCubit cubit) => cubit.state.user);
    return AppPage(
      title: context.s.myQrTitle,
      children: [
        // A code is only useful when the number in it can be paid.
        if (user != null && normalisePhone(user.phone) != null)
          _QrCard(user: user)
        else
          const _MissingPhoneCard(),
      ],
    );
  }
}

/// The code on a white square, with the name and number under it.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.palette.mutedText);
    return SectionCard(
      child: Column(
        children: [
          Text(context.s.myQrHelp, textAlign: TextAlign.center, style: muted),
          const SizedBox(height: AppSizes.gap),
          // White in both themes: a camera cannot read a dark code.
          ColoredBox(
            color: Colors.white,
            child: QrImageView(
              key: K.qrImage,
              data: encodeQr(name: user.fullName, phone: user.phone),
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.gap),
          Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(prettyPhone(user.phone), style: muted),
        ],
      ),
    );
  }
}

/// Tells the user why there is no code and where to fix it.
class _MissingPhoneCard extends StatelessWidget {
  const _MissingPhoneCard();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SectionCard(
      child: Column(
        children: [
          Text(
            s.qrMissingPhone,
            key: K.qrMissingPhone,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.gap),
          PrimaryButton(
            label: s.addPhoneNumber,
            onPressed: () => Navigator.pushNamed(context, Routes.editProfile),
          ),
        ],
      ),
    );
  }
}
