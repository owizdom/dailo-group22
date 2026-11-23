import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../domain/logic/phone_number.dart';
import '../../cubits/profile_cubit.dart';
import '../common/avatar.dart';
import '../common/section_card.dart';

/// Name, email and phone of the signed-in user, with an Edit button.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();
        final muted = TextStyle(color: context.palette.mutedText);
        return SectionCard(
          child: Row(
            children: [
              Avatar.initials(user.fullName, size: 52),
              const SizedBox(width: AppSizes.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    Text(prettyPhone(user.phone), style: muted),
                  ],
                ),
              ),
              IconButton(
                key: K.settingsEditProfile,
                tooltip: strings.settingsEditProfile,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.editProfile),
              ),
            ],
          ),
        );
      },
    );
  }
}
