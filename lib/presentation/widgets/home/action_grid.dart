import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/routes.dart';
import '../../cubits/send_money_cubit.dart';
import 'action_tile.dart';

/// The four actions: two across on a phone, four across when there is room.
class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  static const _fourAcrossFrom = 480.0;

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    final tiles = [
      ActionTile(
        key: K.homeSend,
        icon: Icons.send_outlined,
        label: strings.sendMoney,
        filled: true,
        onTap: () {
          // A new payment never starts from a half-finished one.
          context.read<SendMoneyCubit>().start();
          Navigator.pushNamed(context, Routes.sendMoney);
        },
      ),
      ActionTile(
        key: K.homeQr,
        icon: Icons.qr_code_2,
        label: strings.generateQr,
        onTap: () => Navigator.pushNamed(context, Routes.generateQr),
      ),
      ActionTile(
        key: K.homeAirtime,
        icon: Icons.phone_android,
        label: strings.buyAirtime,
        onTap: () => Navigator.pushNamed(context, Routes.buyAirtime),
      ),
      ActionTile(
        key: K.homeData,
        icon: Icons.cell_tower,
        label: strings.buyData,
        onTap: () => Navigator.pushNamed(context, Routes.buyData),
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= _fourAcrossFrom;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: wide ? 1.9 : 2.1,
          children: tiles,
        );
      },
    );
  }
}
