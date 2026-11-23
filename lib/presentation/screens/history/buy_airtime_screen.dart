import 'package:flutter/material.dart';

import '../../../core/keys.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../domain/entities/transaction_record.dart';
import '../../widgets/history/top_up_page.dart';

/// Buys airtime for this line or another number.
class BuyAirtimeScreen extends StatelessWidget {
  const BuyAirtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.s;
    return TopUpPage(
      type: TxType.airtime,
      title: strings.buyAirtime,
      amountKey: K.airtimeAmount,
      amountLabel: strings.amount,
      phoneKey: K.airtimePhone,
      buyKey: K.airtimeBuy,
      buyLabel: strings.buyAirtime,
    );
  }
}
