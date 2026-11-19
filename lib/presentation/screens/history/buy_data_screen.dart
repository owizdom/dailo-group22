import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../widgets/history/top_up_page.dart';

/// Opens the operator's data bundle menu and records the purchase.
class BuyDataScreen extends StatelessWidget {
  const BuyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return TopUpPage(
      type: TxType.data,
      title: strings.buyData,
      intro: strings.dataIntro,
      amountKey: K.dataAmount,
      amountLabel: strings.dataAmountLabel,
      buyKey: K.dataBuy,
      buyLabel: strings.dataBuyButton,
    );
  }
}